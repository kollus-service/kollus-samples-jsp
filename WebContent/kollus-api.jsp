<%@ page language="java" contentType="text/html; charset=EUC-KR"
    pageEncoding="EUC-KR"%>
<%@ page import="java.io.BufferedReader" %>
<%@ page import="java.io.DataOutputStream" %>
<%@ page import="java.io.InputStream" %>
<%@ page import="java.io.InputStreamReader" %>
<%@ page import="java.net.HttpURLConnection" %>
<%@ page import="java.net.URL" %>
<%@ page import="java.nio.charset.Charset" %>
<%@ page import="java.util.Enumeration" %>
<%@ page import="java.util.HashMap" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=EUC-KR">
<title>Kollus API Sample</title>
</head>
<body>
<%!
String api_access_token = "<API_ACCESS_TOKEN>";

public String send(String _url, String method, HashMap<String, String> headers, String body) throws Exception {
	URL url = new URL(_url);

	HttpURLConnection connection = null;
	try {
		connection = (HttpURLConnection) url.openConnection();
		connection.setConnectTimeout(30 * 1000);
	} catch (Exception e) {
		Thread.sleep(5000L);
		connection = (HttpURLConnection) url.openConnection();
	}

	connection.setRequestMethod(method);
	if (headers != null) {
		for (String key : headers.keySet()) {
			connection.setRequestProperty(key, headers.get(key));
		}
	}
	if (body != null && body.trim() != "") {
		if ("POST".equals(method) || "PUT".equals(method)) {
			connection.setDoOutput(true);
			DataOutputStream wr = new DataOutputStream(connection.getOutputStream());
			byte[] bodybytes = body.getBytes("UTF-8");
			wr.write(bodybytes);
			wr.flush();
		}
	}
	int responseCode = 0;
	int retry = 0;
	try {
		responseCode = connection.getResponseCode();
	} catch (Exception e) {
		System.out.println("Raise ERR getResponseCode()");
		while (retry < 5 && responseCode == 0) {
			Thread.sleep(2000L);
			try {
				responseCode = connection.getResponseCode();
			} catch (Exception sub) {
				System.out.println("Raise Sub ERR getResponseCode()");
			}
			retry += 1;
		}
	}
	BufferedReader in = new BufferedReader(
			new InputStreamReader(connection.getInputStream(), Charset.forName("UTF-8")));
	String inputLine;
	StringBuffer response = new StringBuffer();

	int inIdx = 0;
	while ((inputLine = in.readLine()) != null) {
		response.append(inputLine);
		inIdx++;
	}
	in.close();
	return response.toString();
}
%>

<%
String api = "https://api.kr.kollus.com/0/media_auth/upload/create_url.json";
String _url = api + "?access_token="+api_access_token;
HashMap<String, String> headers = new HashMap<String, String>();
headers.put("Content-Type", "application/x-www-form-urlencoded;charset=utf-8");
String apiRes = send(_url, "POST", headers, null);
%>
<%=apiRes %>
</body>
</html>