<%@page import="java.nio.charset.Charset"%>
<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ page import="org.apache.tomcat.util.codec.binary.Base64"%>
<%@ page import="javax.crypto.Mac"%>
<%@ page import="javax.crypto.spec.SecretKeySpec"%>
<%@ page import="java.util.Date"%>
<%@ page import="java.util.Calendar"%>
<%@ page import="java.security.InvalidKeyException"%>
<%@ page import="java.security.NoSuchAlgorithmException"%>
<%@ page import="java.util.List"%>
<%@ page import="java.util.ArrayList"%>
<%@ page import="java.util.HashMap"%>
<%@ page import="com.google.gson.Gson"%>
<%@ page import="com.google.gson.internal.LinkedTreeMap" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title>Play Video</title>
</head>
<body>

	<%
		if (request.getMethod() != "POST") {
			response.setStatus(401);
			response.getWriter().write("This Method(" + request.getMethod() + ") is Not Supported");
		}
	%>
	<%
	final String securityKey = "hdayng2";
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
		String p_items = request.getParameter("items");
		List<LinkedTreeMap<String, Object>> items = new Gson().fromJson(p_items, List.class);
		System.out.println(items);
		List<HashMap<String, Object>> resultPayload = new ArrayList<HashMap<String, Object>>();

		for (LinkedTreeMap item : items) {
			
			int kind = (int)Float.parseFloat(item.get("kind").toString());
			String clientUserId = item.get("client_user_id").toString();
			String mediaContentKey = item.get("media_content_key").toString();
			long start_at = Long.parseLong(item.get("start_at").toString());
			
			HashMap<String, Object> resultItem = new HashMap<String, Object>();
			resultItem.put("kind", kind);
			resultItem.put("media_content_key", mediaContentKey);
			resultItem.put("result",playing ? 1: 0);
			if(playing){
			resultItem.put("message", msg);
			}
			switch (kind) {
			case 1:
				break;
			case 2:
				break;
			case 3:
				resultItem.put("start_at", start_at);
				break;

			}
			resultPayload.add(resultItem);
		}
		HashMap<String, Object> payload = new HashMap<String, Object>();
		payload.put("data", resultPayload);
		String responseValue = jwt_encode(new Gson().toJson(payload), securityKey);
		response.setStatus(200);
		response.setContentType("plain/text; charset=utf-8");
		response.setHeader("X-Kollus-UserKey", customKey);
		response.getWriter().write(responseValue);
		response.getWriter().close();
	%>

</body>
</html>