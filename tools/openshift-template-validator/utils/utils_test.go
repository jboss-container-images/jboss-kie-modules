package utils

import (
	"fmt"
	"github.com/jboss-container-images/jboss-kie-modules/tools/openshift-template-validator/utils"
	"github.com/openshift/origin/_vendor/github.com/containers/storage/pkg/testutil/assert"
	"testing"
)

func TestParseHAProxyTimeout(t *testing.T) {

	values := []string{"10000us","1000ms", "10s", "1m", "1h", "1d"}

	for _, value := range values{
		err := utils.ParseHAProxyTimeout(value)
		if err != nil {
			t.Errorf("Failed to parse value %s. %s", value, err.Error())
		}
	}

	// test wrong value
	err := utils.ParseHAProxyTimeout("10ts")
	if err != nil {
		assert.Equal(t, err.Error(), "provided value does not match the regex ^[0-9]*(us|ms|s|m|h|d)$")
	}

}

func TestParsePort(t *testing.T) {

	err := utils.ParsePort("1234")
	if err != nil {
		t.Errorf("Failed to parse value %s. %s", "1234", err.Error())
	}

	invalidValues := []string{"hello-xuxa","8080z", "10s", "1m", "1h", "1d"}
	for _, value := range invalidValues{
		err := utils.ParsePort(value)
		if err != nil {
			assert.Equal(t, err.Error(), fmt.Sprintf("strconv.Atoi: parsing \"%s\": invalid syntax", value))
		}
	}

}

func TestInArray(t *testing.T) {

	arrayA := []string{"A", "good", "valuea"}
	assert.Equal(t, true, In_array(arrayA, "good"))
	assert.Equal(t, false, In_array(arrayA, "bad"))
}