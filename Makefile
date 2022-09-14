webhookName := check-labels
image       := ashoka007/$(webhookName)
version     := 0.5
tag         := $(image):$(version)

ns          := dac-check-labels

all: delete clean certgen yamlgen redeploy

build:
	@echo "####################"
	@echo "## $(@)"
	@echo "####################"
	docker build --platform=linux/amd64 -t $(tag) . && docker push $(tag)

delete:
	@echo "####################"
	@echo "## $(@)"
	@echo "####################"
	-kubectl delete pod $(webhookName) -n $(ns) --force --grace-period=0
	@echo
	-kubectl delete validatingwebhookconfigurations.admissionregistration.k8s.io $(webhookName)
	@echo
	-kubectl delete -f manifests/webhook.yaml

redeploy: build deploy

deploy:
	@echo "####################"
	@echo "## $(@)"
	@echo "####################"
	-kubectl create -f manifests/k8s.yaml
	@echo
	-kubectl create -f manifests/webhook.yaml
	@echo
	kubectl get validatingwebhookconfigurations.admissionregistration.k8s.io
	kubectl get pods -n $(ns)

.PHONY: test clean

clean:
	@echo "####################"
	@echo "## $(@)"
	@echo "####################"
	-rm -f conf/ext.cnf
	-rm -f certs/ca.* 
	-rm -f manifests/*.yaml

test:
	@echo "####################"
	@echo "## $(@)"
	@echo "####################"
	-kubectl create -f tests/
	@echo
	-kubectl get pods -n test-case-excl
	-kubectl get pods -n test-case-incl
	@echo
	-kubectl delete -f tests/

certgen:
	@echo "####################"
	@echo "## $(@)"
	@echo "####################"
	@sed -e "s/__NAMESPACE__/$(ns)/g" -e "s/__WEBHOOK__/$(webhookName)/g" templates/ext.tpl >conf/ext.cnf
	openssl req -x509 -newkey rsa:4096 -nodes -out certs/ca.crt -keyout certs/ca.key -days 365 -config conf/ext.cnf -extensions req_ext
	ls -l certs/

yamlgen:
	@echo "####################"
	@echo "## $(@)"
	@echo "####################"
	@sed -e "s/__NAMESPACE__/$(ns)/g" -e "s|__TAG__|$(tag)|g" -e "s/__WEBHOOK__/$(webhookName)/g" templates/k8s.tpl >manifests/k8s.yaml
	@nl manifests/k8s.yaml | head
	@sed -e "s/__NAMESPACE__/$(ns)/g" -e "s/__WEBHOOK__/$(webhookName)/g" -e "s/__CA_BUNDLE__/$(shell cat certs/ca.crt | base64 | tr -d '\n')/g" templates/webhook.tpl >manifests/webhook.yaml
	nl manifests/webhook.yaml | tail
