<%@page import="java.net.URLEncoder"%>
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
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title>Play Video</title>
</head>
<body>
	<%
		final String securityKey = "hdyang2";
		final String customKey = "1ba769ae9972603d72658b8566dc4fa2e5782dcfede54c527831b70f4aa9d7f3";
		final String clientUserId = "CLIENT_USER_ID";
		final int expireTime = 60 * 24 * 2; // 5 MINUTES
		final String[] mediaItems = { "Mf8ufQ6h" };
	%>
	<%!public String createPayload(String cuid, int exptMinutes, String... mediaKeys) {
		if (mediaKeys == null || mediaKeys.length <= 0) {
			return null;
		}
		if (exptMinutes <= 0) {
			return null;
		}
		String fmt_payloadJson = "{\"cuid\": \"%s\",\"expt\": %d,\"mc\": [%s]}";
		StringBuilder sb = new StringBuilder();

		int nMediakeys = mediaKeys.length;
		for (int idx = 0; idx < nMediakeys; idx++) {
			sb.append("{\"mckey\":\"");
			sb.append(mediaKeys[idx]);
			//sb.append("\", \"mcpf\":\"zeusedu-pc1-hd\"}");
			sb.append("\"}");
			if (idx < nMediakeys - 1) {
				sb.append(",");
			}
		}
		Date now = new Date();
		Calendar c = Calendar.getInstance();
		c.setTime(now);
		c.add(Calendar.MINUTE, exptMinutes);
		long expt = c.getTime().getTime() / 1000;
		final String payloadJson = String.format(fmt_payloadJson, cuid, expt, sb.toString());
		return payloadJson;
	}%>
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
	<%!public String getUrl(String userkey, String token) {
		return String.format("http://v.kr.kollus.com/s?jwt=%s&custom_key=%s&a", token, userkey);
	}%>


	<%!public String getSrUrl(String userkey, String token) {
		return String.format("http://v.kr.kollus.com/sr?jwt=%s&custom_key=%s&a", token, userkey);
	}%>
	<%
		String payload = createPayload(clientUserId, expireTime, mediaItems);
		String token = jwt_encode(payload, securityKey);
		String url = getUrl(customKey, token);
		String srurl = getSrUrl(customKey, token);
	%>
	<h1>KollusPlayer</h1>
	<iframe src="<%=url%>"></iframe>


	<h1>SR MODE<h1>
			<video width="320" height="240"> <source
				src="<%=srurl %>" type="video/mp4"> Your browser does not
			support the video tag. </video>
</html>
</body>

</html>