package org.proxily.lambdas.fileuploadlambda;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.LambdaLogger;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.S3Event;
import com.amazonaws.services.s3.event.S3EventNotification.S3EventNotificationRecord;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Statement;


public class FileUploadLambda implements RequestHandler<S3Event, Object> {

    public Object handleRequest(S3Event input, Context context) {
        LambdaLogger logger = context.getLogger();
        for (S3EventNotificationRecord record : input.getRecords()) {
            String[] key = record.getS3().getObject().getKey().replace(".jpeg", "").split("_");
            String userID = key[0];
            String timestamp = key[1].replace("%3A", ":").replace("+", " ");
            logger.log("UserID = " + userID);
            logger.log("Timestamp = " + timestamp);
            logger.log("RDS CLient building");
            logger.log(System.getenv("RDS_ENDPOINT"));
            String url       = "jdbc:mysql://" + System.getenv("RDS_ENDPOINT") + "/Proxily?autoReconnect=true&useSSL=false";
            logger.log(url);
            String user      = "admin";
            String password  = "password";
            try {
                Connection conn = DriverManager.getConnection(url, user, password);
                String cmd = "UPDATE posts SET FileUploaded=1 WHERE UserID='" + userID + "' AND Timestamp='" + timestamp + "';";
                logger.log(cmd);
                Statement stmt = conn.createStatement();
                stmt.executeUpdate(cmd);
            } catch (SQLException e) {
                logger.log("SQL Exception: " + e.getMessage());
                logger.log(e.getSQLState());
            }

        }
        logger.log("Success!");
        return null;
    }
}