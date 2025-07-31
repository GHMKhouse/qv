import std/[streams, endians]

type
  BMPImage* = object
    width*, height*: int
    data*: seq[byte]
    bitsPerPixel*: int # 添加位深度信息

proc readBMP*(filePath: string): BMPImage =
  ## 读取 BMP 文件，返回 BMPImage 对象
  ## 支持 1位(单色), 24位(RGB) 和 32位(RGBA) 格式

  var fs = newFileStream(filePath, fmRead)
  if fs == nil:
    raise newException(IOError, "无法打开文件: " & filePath)

  try:
    # 读取 BMP 文件头 (14 字节)
    var fileHeader: array[14, byte]
    if fs.readData(fileHeader.addr, 14) != 14:
      raise newException(IOError, "无效的 BMP 文件头")

    # 检查魔数 "BM"
    if fileHeader[0] != 'B'.byte or fileHeader[1] != 'M'.byte:
      raise newException(ValueError, "不是有效的 BMP 文件")

    # 读取 DIB 头信息 (至少 40 字节)
    var dibHeaderSize: uint32
    littleEndian32(dibHeaderSize.addr, fileHeader[10].addr)

    if dibHeaderSize < 40:
      raise newException(ValueError, "不支持的 BMP 格式: DIB 头太小")

    # 读取 BITMAPINFOHEADER (40 字节)
    var infoHeader: array[40, byte]
    if fs.readData(infoHeader.addr, 40) != 40:
      raise newException(IOError, "无效的 BMP 信息头")

    # 解析宽度和高度
    var width, height: int32
    littleEndian32(width.addr, infoHeader[4].addr)
    littleEndian32(height.addr, infoHeader[8].addr)

    if width <= 0 or height == 0:
      raise newException(ValueError, "无效的图像尺寸")

    # 检查位深度
    var bitsPerPixel: int16
    littleEndian16(bitsPerPixel.addr, infoHeader[14].addr)
    result.bitsPerPixel = bitsPerPixel.int

    # 检查压缩方式 (0 = 未压缩)
    var compression: uint32
    littleEndian32(compression.addr, infoHeader[16].addr)
    if compression != 0:
      raise newException(ValueError, "不支持压缩的 BMP 格式")

    # 获取像素数据偏移量
    var dataOffset: uint32
    littleEndian32(dataOffset.addr, fileHeader[10].addr)

    # 移动到像素数据位置
    fs.setPosition(dataOffset.int)

    # 计算行大小 (包含填充)
    let rowSize = ((width * bitsPerPixel.int + 31) div 32) * 4

    # 初始化图像数据
    result.width = width.int
    result.height = height.abs.int
    let isTopDown = height < 0
    height = height.abs

    case bitsPerPixel
    of 1:
      # 1位位深度 - 单色图像

      # 读取调色板 (4字节 * 2种颜色)
      var palette: array[8, byte]
      fs.setPosition(14 + 40) # 文件头 + 信息头
      if fs.readData(palette.addr, 8) != 8:
        raise newException(IOError, "读取调色板失败")

      # 创建调色板数组 [颜色0, 颜色1]
      let colors = [
        [palette[2], palette[1], palette[0]],            # 颜色0 (BGR -> RGB)
        [palette[6], palette[5], palette[4]]             # 颜色1 (BGR -> RGB)
      ]
      # 初始化数据为24位RGB格式
      result.data = newSeq[byte](result.width * result.height * 3)

      # 读取像素数据
      for y in 0..<height.int:
        var rowData = newSeq[byte](rowSize)
        if fs.readData(rowData[0].addr, rowSize) != rowSize:
          raise newException(IOError, "图像数据不完整")

        # 处理行数据
        let targetY = if isTopDown: y else: height.int - y - 1
        let targetIndex = targetY * result.width * 3

        # 处理每个像素
        for x in 0..<result.width:
          let byteIndex = x div 8
          let bitIndex = 7 - (x mod 8) # 高位在前
          let bitValue = (rowData[byteIndex] shr bitIndex) and 1
          let color = colors[bitValue]

          # 存储RGB值
          let dstIndex = targetIndex + x * 3
          result.data[dstIndex] = color[0] # R
          result.data[dstIndex + 1] = color[1] # G
          result.data[dstIndex + 2] = color[2] # B

    of 24, 32:
      # 24位或32位图像
      let channels = if bitsPerPixel == 24: 3 else: 4
      result.data = newSeq[byte](result.width * result.height * channels)

      for y in 0..<height.int:
        var rowData = newSeq[byte](rowSize)
        if fs.readData(rowData[0].addr, rowSize) != rowSize:
          raise newException(IOError, "图像数据不完整")

        # 处理行数据
        let targetY = if isTopDown: y else: height.int - y - 1
        let targetIndex = targetY * result.width * channels

        # 复制数据并转换 BGR(A) 为 RGB(A)
        for x in 0..<result.width:
          let srcIndex = x * channels
          let dstIndex = targetIndex + x * channels

          # 交换 R 和 B 通道
          result.data[dstIndex] = rowData[srcIndex + 2] # R
          result.data[dstIndex + 1] = rowData[srcIndex + 1] # G
          result.data[dstIndex + 2] = rowData[srcIndex] # B

          if channels == 4:
            result.data[dstIndex + 3] = rowData[srcIndex + 3] # A

    else:
      raise newException(ValueError, "不支持的位深度: " & $bitsPerPixel)

  finally:
    fs.close()
