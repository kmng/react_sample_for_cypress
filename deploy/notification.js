exports.handler = async (event, context) => {
  try {


    return {
      statusCode: 200,
      body: JSON.stringify('Notification sent successfully'),
    };
  } catch (error) {
    console.error('Error sending notification:', error);
    throw error;
  }
};
