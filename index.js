// AWS Lambda proxy for triggering Jenkins jobs

// Environment variables: HEADERS, TARGET_HOSTNAME, TARGET_METHOD, TARGET_PATH
// Data variables:
//    auth/github_user, auth/github_token, job_name, job_token, build_cause

var https = require('https');

var config = {
    hostname: process.env.TARGET_HOSTNAME,
    path: process.env.TARGET_PATH,
    method: process.env.TARGET_METHOD,
    user: process.env.JENKINS_USER,
    pswd: process.env.JENKINS_PSWD,
    headers: JSON.parse(`{"headers": ${process.env.HEADERS}}`).headers
};

exports.handler = (event, context, callback) => {
    // Display all data passed in
    console.log("Event: ", JSON.stringify(event, null, 2))
    console.log("Context: ", JSON.stringify(context, null, 2))
    var uri = "job/" + event.body.JobName + "/build?token=" + event.body.JobToken + "&cause=" + event.body.BuildCause
    console.log("URI: " + uri)
    var auth = config.user + ":" + config.pswd
    console.log("Auth: " + auth)

    if (! ("headers" in event))
        return callback("Missing headers in event body, you need to set body mapping in gateway.");
    if (! ("body" in event))
        return callback("Missing body in event body, you need to set body mapping in gateway.");

    var headers = { };
    config.headers.forEach(
        (header) => {
            if (! (header in event.headers))
                return callback(`Missing header "${header}"`);
            else
                headers[header] = event.headers[header];
        });

    var options = {
        hostname: config.hostname,
        port: 443,
        path: config.path + uri,
        method: 'GET',
        //headers
        headers: {
          'Authorization': 'Basic ' + new Buffer(auth).toString('base64')
        }
    };

    var req = https.request(options, (res) => {
        console.log('Response statusCode: ', res.statusCode);
        console.log('Response headers: ', res.headers);
        //console.log('Response: ', JSON.stringify(res, null, 2));

        var data = '';
        res.on('data', (d) => {
            data += d;
        });

        res.on('end', (e) => {
            if(res.statusCode < 400){
                console.log("Success for event: " + JSON.stringify(event.body));
                callback(null, data);
            }
            else {
                callback(data);
            }
        });

    });

    req.on('error', (err) => {
        console.log("Error in the lambda proxy: " + err);
        callback(err);
    });

    req.write(JSON.stringify(event.body));

    req.end();

};
1
