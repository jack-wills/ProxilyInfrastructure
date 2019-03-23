package org.proxily.lambdas.reaperlambda;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.LambdaLogger;
import com.amazonaws.services.lambda.runtime.RequestHandler;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Statement;


public class ReaperLambda implements RequestHandler<Object, Object> {

    public Object handleRequest(Object input, Context context) {
        LambdaLogger logger = context.getLogger();
        String url       = "jdbc:mysql://" + System.getenv("RDS_ENDPOINT") + "/Proxily?autoReconnect=true&useSSL=false";
        logger.log(url);
        String user      = "admin";
        String password  = "password";
        try {
            Connection conn = DriverManager.getConnection(url, user, password);
            Statement stmt = conn.createStatement();
            stmt.executeUpdate("DELETE FROM posts WHERE Timestamp < NOW() - INTERVAL 6 DAY - INTERVAL 22 HOUR;");
            conn.close();
        } catch (SQLException e) {
            logger.log("SQL Exception: " + e.getMessage());
            logger.log(e.getSQLState());
        }
        return null;
    }
}

