import com.sun.net.httpserver.HttpServer;
import java.io.IOException;
import java.io.OutputStream;
import java.net.InetSocketAddress;

public class Main {
    public static void main(String[] args) throws IOException {
        String appName = System.getenv("APP_NAME");
        if (appName == null) appName = "unknown-java-app";
        
        String appPortStr = System.getenv("APP_PORT");
        int appPort = appPortStr != null ? Integer.parseInt(appPortStr) : 8003;
        
        String logLevel = System.getenv("LOG_LEVEL");
        if (logLevel == null) logLevel = "info";

        System.out.printf("[%s] Starting on port %d (log_level=%s)%n", appName, appPort, logLevel);

        HttpServer server = HttpServer.create(new InetSocketAddress(appPort), 0);
        
        String finalAppName = appName;
        String finalLogLevel = logLevel;
        String finalPortStr = appPortStr;
        
        server.createContext("/", exchange -> {
            String response = String.format(
                "{\"service\":\"%s\",\"port\":\"%s\",\"log_level\":\"%s\",\"config_source\":\"environment variable\",\"message\":\"Config loaded successfully!\"}",
                finalAppName, finalPortStr, finalLogLevel
            );
            exchange.getResponseHeaders().set("Content-Type", "application/json");
            exchange.sendResponseHeaders(200, response.getBytes().length);
            OutputStream os = exchange.getResponseBody();
            os.write(response.getBytes());
            os.close();
        });

        server.setExecutor(null);
        server.start();
    }
}
