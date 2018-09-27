package validation

import (
	"github.com/jboss-container-images/jboss-kie-modules/tools/openshift-template-validator/utils"
	"strings"
)

func validateAnnotations(annotations map[string]string) {

	for annotationKey, annotationValue := range annotations {
		if annotationValue == "" {
			validationErrors["Annotations"] = append(validationErrors["Annotations"], "Annotation "+annotationKey+" is empty.")
		}

		if utils.ValidateTemplateVersion {
			if annotationKey == "version" {
				if annotationValue != utils.ProvidedTemplateVersion {
					validationErrors["Annotations"] = append(validationErrors["Annotations"], "The provided version does not match the template version. Provided ["+utils.ProvidedTemplateVersion+"] - Template Version: "+annotationValue+".")
				}
			}
		}

		// validate annotations
		// validate the required annotation tags, for now only jboss
		if annotationKey == "tags" {
			tags := strings.Split(annotationValue, ",")
			if !utils.In_array(tags, "jboss") {
				validationErrors["Annotations"] = append(validationErrors["Annotations"], "The tag jboss was not found in template tags.")
			}
		}

		// validate openshift.io/provider-display-name, should be Red Hat, Inc
		if annotationKey == "openshift.io/provider-display-name" {
			if !strings.Contains(annotationValue, "Red Hat, Inc.") {
				validationErrors["Annotations"] = append(validationErrors["Annotations"], "The annotation openshift.io/provider-display-name does not have the required value [Red Hat, Inc.]")
			}
		}

		// validate template.openshift.io/support-url, should be https://access.redhat.com
		if annotationKey == "template.openshift.io/support-url" {
			if !strings.Contains(annotationValue, "https://access.redhat.com") {
				validationErrors["Annotations"] = append(validationErrors["Annotations"], "The annotation template.openshift.io/support-url does not have the required value [https://access.redhat.com]")
			}
		}

		// validate template.openshift.io/bindable, should be false
		if annotationKey == "template.openshift.io/bindable" {
			if !strings.Contains(annotationValue, "false") {
				validationErrors["Annotations"] = append(validationErrors["Annotations"], "The annotation template.openshift.io/bindable does not have the required value [false]")
			}
		}
	}

	mapRequiredAnnotations := make(map[string]string)
	var tempRequiredAnnotations []string
	if len(utils.CustomAnnotation) > 0 {
		for _, ca := range strings.Split(utils.CustomAnnotation, ",") {
			if strings.Contains(ca, "=") {
				tempAnnotation := strings.Split(ca, "=")
				mapRequiredAnnotations[tempAnnotation[0]] = tempAnnotation[1]
			} else {
				tempRequiredAnnotations = append(tempRequiredAnnotations, ca)
			}
		}
	}

	if len(mapRequiredAnnotations) > 0 {
		for customk, customv := range mapRequiredAnnotations {
			_, found := annotations[customk]
			if !found {
				validationErrors["Annotations"] = append(validationErrors["Annotations"], "Annotation "+customk+" was not found in the template annotations.")
			} else {
				for ak, av := range annotations {
					if ak == customk && av != customv {
						validationErrors["Annotations"] = append(validationErrors["Annotations"], "Annotation "+customk+" was found in the template annotations but does not contain the required value["+customv+"].")
					}
				}
			}
		}
	}

	tempRequiredAnnotations = append(tempRequiredAnnotations, utils.RequiredAnnotations...)
	for _, tempRequiredAnnotation := range tempRequiredAnnotations {
		_, found := annotations[tempRequiredAnnotation]
		if !found {
			validationErrors["Annotations"] = append(validationErrors["Annotations"], "Annotation "+tempRequiredAnnotation+" was not found in the template annotations.")
			tempRequiredAnnotation = ""
		}
	}
}
