load ../../../tests/bats/common/logging

function assert_xml() {
  local file=$1
  local expected=$2
  local xml=$(xmllint $file)

  diff -Ew <(echo $xml | xmllint --format -) $expected
}
