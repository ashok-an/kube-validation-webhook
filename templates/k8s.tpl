---
apiVersion: v1
kind: Namespace
metadata:
   name: __NAMESPACE__
---
apiVersion: v1
kind: Pod
metadata:
  name: __WEBHOOK__-pod
  labels:
    app: __WEBHOOK__
  namespace: __NAMESPACE__
spec:
  restartPolicy: OnFailure
  containers:
    - name: __WEBHOOK__-container
      image: __TAG__ 
      imagePullPolicy: Always
---
apiVersion: v1
kind: Service
metadata:
  name: __WEBHOOK__-svc
  namespace: __NAMESPACE__
spec:
  selector:
    app: __WEBHOOK__
  ports:
  - port: 443
    targetPort: 5000
