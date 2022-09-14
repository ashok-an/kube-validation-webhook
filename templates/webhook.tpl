apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingWebhookConfiguration
metadata:
  name: ngaddons-__WEBHOOK__
  namespace: __NAMESPACE__
webhooks:
  - name: ngaddons.__WEBHOOK__
    failurePolicy: Fail
    sideEffects: None
    admissionReviewVersions: ["v1","v1beta1"]
    rules:
      - apiGroups: ["apps", ""]
        resources:
          - "deployments"
          - "pods"
        apiVersions:
          - "*"
        operations:
          - CREATE
    clientConfig:
      service:
        name: __WEBHOOK__-svc
        namespace: __NAMESPACE__
        path: /validate/
      caBundle: __CA_BUNDLE__
