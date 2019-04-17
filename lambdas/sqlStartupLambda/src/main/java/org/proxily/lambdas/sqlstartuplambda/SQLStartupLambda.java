package org.proxily.lambdas.sqlstartuplambda;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.LambdaLogger;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.SNSEvent;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.Arrays;


public class SQLStartupLambda implements RequestHandler<SNSEvent, Object> {

    public Object handleRequest(SNSEvent input, Context context) {
        LambdaLogger logger = context.getLogger();

        logger.log(System.getenv("RDS_ENDPOINT"));
        String url       = "jdbc:mysql://" + System.getenv("RDS_ENDPOINT") + "?autoReconnect=true&useSSL=false";
        logger.log(url);
        String user      = "admin";
        String password  = "password";
        try {

            ClassLoader classLoader = getClass().getClassLoader();

            File cityFile = new File(classLoader.getResource("startupScript.sql").getFile());
            BufferedReader in = new BufferedReader(new FileReader(cityFile));
            String str;
            StringBuffer sb = new StringBuffer();
            while ((str = in.readLine()) != null) {
                sb.append(str + "\n ");
            }
            in.close();
            String[] commandsPlus1 = sb.toString().split(";");
            String[] commands = Arrays.copyOf(commandsPlus1, commandsPlus1.length-1);
            Connection conn = DriverManager.getConnection(url, user, password);
            Statement stmt = conn.createStatement();
            for (String cmd: commands) {
                logger.log(cmd);
                stmt.addBatch(cmd);
            }
            stmt.addBatch("CREATE USER backend IDENTIFIED BY '" + System.getenv("RDS_PASSWORD") + "'");
            stmt.addBatch("GRANT ALL PRIVILEGES ON Proxily.* TO 'backend'@'%'");
            stmt.executeBatch();
            conn.close();
        } catch (SQLException e) {
            logger.log("SQL Exception: " + e.getMessage());
            logger.log(e.getSQLState());
        } catch (IOException e) {
            logger.log("IO Exception: " + e.getMessage());
            logger.log(e.toString());
        }
        return null;
    }
}

