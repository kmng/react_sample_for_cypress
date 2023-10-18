const AWS = require('aws-sdk');
const sns = new AWS.SNS();

exports.handler = async (event, context) => {
  try {

    // Get the SNS topic ARN from the environment variable
    const snsTopicArn = process.env.SNS_TOPIC_ARN;

    // get parameter

    const pipeline = event.detail.pipeline;

    if (!snsTopicArn) {
      throw new Error('SNS_TOPIC_ARN environment variable is not set.');
    }

    const message = 'Your build pipeline :'+pipeline+' has failed.';

    const params = {
      Message: message,
      TopicArn: snsTopicArn,
      Subject: 'Pipeline Failure Notification',
    };

    await sns.publish(params).promise();
    
    return {
      statusCode: 200,
      body: JSON.stringify('Notification sent successfully'),
    };
  } catch (error) {
    console.error('Error sending notification:', error);
    throw error;
  }
};
