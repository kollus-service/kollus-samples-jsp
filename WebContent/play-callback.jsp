<%@page import="java.nio.charset.Charset"%>
<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ page import="org.apache.tomcat.util.codec.binary.Base64"%>
<%@ page import="javax.crypto.Mac"%>
<%@ page import="javax.crypto.spec.SecretKeySpec"%>
<%@ page import="java.util.Date"%>
<%@ page import="java.util.Calendar"%>
<%@ page import="java.util.HashMap"%>
<%@ page import="com.google.gson.Gson"%>
<%@ page import="java.security.InvalidKeyException"%>
<%@ page import="java.security.NoSuchAlgorithmException"%>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title>Play Video</title>
</head>
<body>
	<%
		final String securityKey = "SECURITY_KEY";
		final String customKey = "CUSTOM_KEY";
		final int expireTime = 30;
		final String msg = "This video is not permitted to you.";
		final boolean playing = true;
	%>
	<%!public String jwt_encode(String payload, String secretKey) throws InvalidKeyException, NoSuchAlgorithmException {
		String header = "{\"typ\": \"JWT\", \"alg\": \"HS256\"}";
		Charset charset = Charset.forName("UTF-8");
		String h = Base64.encodeBase64URLSafeString(header.getBytes(charset));
		String p = Base64.encodeBase64URLSafeString(payload.getBytes(charset));
		String content = String.format("%s.%s", h, p);
		final Mac mac = Mac.getInstance("HmacSHA256");
		mac.init(new SecretKeySpec(secretKey.getBytes(charset), "HmacSHA256"));
		byte[] signatureBytes = mac.doFinal(content.getBytes(charset));
		String signature = Base64.encodeBase64URLSafeString(signatureBytes);
		return String.format("%s.%s", content, signature);
	}%>

	<%
		int kind = Integer.parseInt(request.getParameter("kind"));

		String clientUserId = request.getParameter("client_user_id");
		String mediaContentKey = request.getParameter("media_content_key");

		HashMap<String, Object> payload = new HashMap<String, Object>();
		payload.put("kind", kind);
		payload.put("result", playing ? 1 : 0);
		if (!playing) {
			payload.put("message", msg);
		}

		switch (kind) {
		case 1:
			Calendar c = Calendar.getInstance();
			c.setTime(new Date());
			c.add(Calendar.SECOND, expireTime * 60);
			long expiration_date = c.getTime().getTime() / 1000;
			payload.put("expiration_date", expiration_date);
			break;
		case 3:
			break;
		}
		HashMap<String, Object> data = new HashMap<String, Object>();
		data.put("data", payload);
		String responseValue = jwt_encode(new Gson().toJson(data), securityKey);

		response.setStatus(200);
		response.setHeader("Content-Type", "plain/text; charset=utf-8");
		response.setHeader("X-Kollus-UserKey", customKey);
		response.getWriter().write(responseValue.trim());
		response.getWriter().close();
	%>

</body>
</html>
