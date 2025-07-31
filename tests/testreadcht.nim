import ../src/[readcht, types]
import unittest, streams
test "readChart":
  var s = openFileStream("maps/nulctrl/chart.cht")
  var chart: Chart
  readCht(chart, s)
  echo chart
