import logging
from flask import Flask, jsonify, request

app = Flask('webhook')
app.logger.addHandler(logging.StreamHandler())
app.logger.setLevel(logging.DEBUG)

#Default route
@app.route("/", methods=['GET'])
def hello():
  return jsonify({"message": "Hello validation controller"})


#Health check
@app.route("/ping", methods=['GET'])
def ping():
  return jsonify({'message': 'pong'})


REQUIRED_LABELS = ['ngaddons/ownerCec', 'ngaddons/webexRoomId', 'ngaddons/appName']

@app.route('/validate', methods=['POST'])
def deployment_webhook():
  r = request.get_json()

  req = r.get('request', {})
  #app.logger.debug(f"+ request: {req}")
  try:
    if not req:
      return send_response(False, '<no uid>', "Invalid request, no payload.request found")

    uid = req.get("uid", '')
    app.logger.debug(f"+ uid: {uid}")
    if not uid:
      return send_response(False, '<no uid>', "Invalid request, no payload.request.uid found")

    labels = req.get("object", {}).get("metadata", {}).get("labels")
    app.logger.debug(f"+ labels: {labels}")
    if 'ngaddons/bypass' in labels:
      return send_response(True, uid, "Request bypassed as 'ngaddons/bypass' is set")

    missing = [ l for l in REQUIRED_LABELS if l not in labels ]
    app.logger.debug(f"+ missing: {missing}")
    if missing:
      return send_response(False, uid, f"Missing labels: {missing}")

  except Exception as e:
    return send_response(False, uid, f"Webhook exception: {e}")

  #Send OK
  return send_response(True, uid, "Request has required labels")


#Function to respond back to the Admission Controller
def send_response(allowed, uid, message):
  app.logger.debug(f"> response:(allowed={allowed}, uid={uid}, message={message})")
  return jsonify({
      "apiVersion": "admission.k8s.io/v1", 
      "kind": "AdmissionReview",
      "response": {
        "allowed": allowed, 
        "uid": uid,
        "status": {"message": message}
    }
  })


if __name__ == "__main__":
  app.run(ssl_context=('certs/ca.crt', 'certs/ca.key'), port=5000, host='0.0.0.0', debug=True)
