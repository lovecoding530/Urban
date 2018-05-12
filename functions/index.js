const functions = require('firebase-functions');

// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//

var braintree = require("braintree");
var gateway = braintree.connect({
    environment:  braintree.Environment.Sandbox,
    merchantId:   'w492nkrqcq8bzyhq',
    publicKey:    '67j52zy23hs8ftpc',
    privateKey:   '61628c4bf8f34b88371b042f85618978'
});

exports.client_token = functions.https.onRequest((request, res) => {
	console.log("Hellow Brain Tree This is Urban");
  gateway.clientToken.generate({})
  .then(function (response) {
	 	console.log("response")
	    res.send(response.clientToken);
	})
  .catch(function (err) {
      console.error(err);
  });
});

exports.pay = functions.https.onRequest((request, res) => {
  var nonce = request.body.payment_method_nonce
  var amount = request.body.amount

  gateway.transaction.sale({
    amount: amount,
    paymentMethodNonce: nonce,
    options: {
      submitForSettlement: true,
    }
  }).then(function (result) {
    if (result.success) {
      console.log('Transaction ID: ' + result.transaction.id);
    } else {
      console.error(result.message);
    }
    res.send(result)
  }).catch(function (err) {
    console.error(err);
  });
})