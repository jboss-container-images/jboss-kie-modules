package validation

import (
	"fmt"
	"github.com/jboss-container-images/jboss-kie-modules/tools/openshift-template-validator/utils"
	"github.com/stretchr/testify/assert"
	"testing"
)

var annotations = make(map[string]string)

func TestAnnotations(t *testing.T) {
	prepare()
	validateAnnotations(annotations)
	if len(validationErrors) > 0 {
		t.Errorf("annotation tests failed: %s", validationErrors)
	}

}

func TestTemplateVersionDifferent(t *testing.T) {
	prepare()
	utils.ValidateTemplateVersion = true
	utils.ProvidedTemplateVersion = "1s0"

	validateAnnotations(annotations)

	if len(validationErrors) < 1 {
		t.Error("Validation error, template version is different than provided, but no issue was reported")
	}
	utils.ValidateTemplateVersion = false
	utils.ProvidedTemplateVersion = ""

}

func TestMissingJBossTag(t *testing.T) {
	prepare()
	ann := annotations
	ann["tags"] = "jbosssssss"

	validateAnnotations(ann)

	assert.Equal(t, len(validationErrors) > 0, true)
	if len(validationErrors) == 0 {
		t.Errorf("annotation tests failed: jboss tag is not present but no error was found")
	}
}

func TestDisplayNameValue(t *testing.T) {
	prepare()
	ann := annotations
	ann["openshift.io/provider-display-name"] = "anyName"
	validateAnnotations(ann)
	assert.Equal(t, len(validationErrors) > 0, true)
	assert.Equal(t, fmt.Sprint(validationErrors), "map[Annotations:[The annotation openshift.io/provider-display-name does not have the required value [Red Hat, Inc.]]]")
}


func TestSupportUrlValue(t *testing.T) {
	prepare()
	ann := annotations
	ann["template.openshift.io/support-url"] = "anyValue"
	validateAnnotations(ann)
	assert.Equal(t, len(validationErrors) > 0, true)
	assert.Equal(t, fmt.Sprint(validationErrors), "map[Annotations:[The annotation template.openshift.io/support-url does not have the required value [https://access.redhat.com]]]")
}

func TestWrongBindableValue(t *testing.T) {
	prepare()
	ann := annotations
	ann["template.openshift.io/bindable"] = "true"
	validateAnnotations(ann)
	assert.Equal(t, len(validationErrors) > 0, true)
	assert.Equal(t, fmt.Sprint(validationErrors), "map[Annotations:[The annotation template.openshift.io/bindable does not have the required value [false]]]")
}


func TestCustomAnnotations(t *testing.T) {
	prepare()
	utils.CustomAnnotation = "valuea=A,foo,bar"
	validateAnnotations(annotations)
	assert.Equal(t, len(validationErrors) > 0, true)
	assert.Equal(t, fmt.Sprint(validationErrors), "map[Annotations:[Annotation valuea was not found in the template annotations. Annotation foo was not found in the template annotations. Annotation bar was not found in the template annotations.]]")
}

func TestCustomAnnotationsWithValue(t *testing.T) {
	prepare()
	utils.CustomAnnotation = "valuea=A,foo,bar"
	ann := annotations
	ann["valuea"] = "B"
	ann["foo"] = "bar"
	ann["bar"] = "foo"
	validateAnnotations(ann)
	assert.Equal(t, len(validationErrors) > 0, true)
	assert.Equal(t, fmt.Sprint(validationErrors), "map[Annotations:[Annotation valuea was found in the template annotations but does not contain the required value[A].]]")
}

func prepare() {
	validationErrors = make(map[string][]string)
	annotations["iconClass"] = "icon-jboss"
	annotations["tags"] = "jboss,gotest"
	annotations["version"] = "10"
	annotations["openshift.io/display-name"] = "annotation tests"
	annotations["openshift.io/provider-display-name"] = "Red Hat, Inc."
	annotations["description"] = "description"
	annotations["template.openshift.io/long-description"] = "long description"
	annotations["template.openshift.io/documentation-url"] = "url"
	annotations["template.openshift.io/support-url"] = "https://access.redhat.com]"
	annotations["template.openshift.io/bindable"] = "false"
}
