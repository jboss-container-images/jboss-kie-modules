package validation

import (
	"bytes"
	"fmt"
	"k8s.io/apimachinery/pkg/api/meta"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/kubernetes/pkg/api/legacyscheme"
	"path/filepath"

	imageapiv1 "github.com/openshift/api/image/v1"
	imageapi "github.com/openshift/origin/pkg/image/apis/image"
	imagevalidation "github.com/openshift/origin/pkg/image/apis/image/validation"

	"github.com/jboss-container-images/jboss-kie-modules/tools/openshift-template-validator/utils"
)

func validateImageStreams(data []byte, file string) {

	if utils.Debug {
		println("\nTrying to validate ImageStreamList")
	}

	var imagestreamlist imageapiv1.ImageStreamList
	// replace the apiVersion from template to image
	data = bytes.Replace(data, []byte("template.openshift.io/v1"), []byte("image.openshift.io/v1"), 1)
	if err := runtime.DecodeInto(legacyscheme.Codecs.UniversalDecoder(), data, &imagestreamlist); err != nil {
		validationErrors["ImageStream"] = append(validationErrors["ImageStream"], filepath.Base(file)+" - "+err.Error())
	}

	if list, err := meta.ExtractList(&imagestreamlist); err == nil {
		runtime.DecodeList(list, legacyscheme.Codecs.UniversalDecoder())

		for i := range list {

			versioned, err := legacyscheme.Scheme.ConvertToVersion(list[i], imageapi.SchemeGroupVersion)
			if err != nil {
				validationErrors["ImageStream"] = append(validationErrors["ImageStream"], err.Error())
			}

			imageStream := versioned.(*imageapi.ImageStream)
			errorPrefix := fmt.Sprintf("ImageStream-%s", imageStream.Name)
			imageStream.Namespace = "default"
			if err := imagevalidation.ValidateImageStream(imageStream); err != nil {
				for _, e := range err {
					validationErrors[errorPrefix] = append(validationErrors[errorPrefix], e.Error())
				}
			}

			if imageStream.Annotations["openshift.io/display-name"] == "" {
				validationErrors[errorPrefix] = append(validationErrors[errorPrefix], "metadata.annotations.openshift.io/display-name cannot be empty.")
			}
			if imageStream.Annotations["openshift.io/provider-display-name"] == "" {
				validationErrors[errorPrefix] = append(validationErrors[errorPrefix], "metadata..annotations.openshift.io/provider-display-name cannot be empty.")
			}

			for _, tag := range imageStream.Spec.Tags {


				if tag.Name == "" {
					validationErrors[errorPrefix] = append(validationErrors[errorPrefix], "tags.spec.name cannot be empty.")
				}
				for _, tempRequiredAnnotation := range utils.RequiredImageStreamAnnotations {
					_, found := tag.Annotations[tempRequiredAnnotation]
					if !found || tag.Annotations[tempRequiredAnnotation] == "" {
						validationErrors[errorPrefix] = append(validationErrors[errorPrefix], "Annotation "+tempRequiredAnnotation+" was not found in the imageStream annotations or is empty.")
						tempRequiredAnnotation = ""
					}
				}
			}
		}
	} else {
		validationErrors["ImageStream"] = append(validationErrors["ImageStream"], filepath.Base(file)+" - "+err.Error())
	}

}
