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
<%@ page import="java.util.Map"%>
<%@ page import="java.util.HashMap"%>
<%@ page import="com.google.gson.Gson"%>
<%@ page import="java.sql.*"%>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title>LMS Callback</title>
</head>
<body>

	<%
		if (request.getMethod() != "POST") {
			response.setStatus(401);
			response.getWriter().write("This Method(" + request.getMethod() + ") is Not Supported");
			response.getWriter().close();
		}
	%>

	<%!class BlockInfo {
		private int idx = 0;
		private boolean is_read_block = false;
		private int time = 0;
		private int percent = 0;

		public BlockInfo() {
		}

		public BlockInfo(int _idx, int read, int _time, int _percent) {
			this.idx = _idx;
			this.is_read_block = read == 0 ? false : true;
			this.time = _time;
			this.percent = _percent;
		}

		public int getIndex() {
			return this.idx;
		}

		public void setIndex(int _value) {
			this.idx = _value;
		}

		public boolean isReadBlock() {
			return this.is_read_block;
		}

		public void setIsReadBlock(boolean _value) {
			this.is_read_block = _value;
		}

		public int getTime() {
			return this.time;
		}

		public void setTime(int _value) {
			this.time = _value;
		}

		public int getPercent() {
			return this.percent;
		}

		public void setPercent(int _value) {
			this.percent = _value;
		}

		@Override
		public String toString() {
			return String.format("{b%d:%d, t%d:%d, p%d:%d}", idx, is_read_block ? 1 : 0, idx, this.time, idx, percent);
		}
	}%>

	<%!public List<BlockInfo> importFromMap(Map<String, Object> map) {
		List<BlockInfo> blockInfos = null;

		if (map.containsKey("block_count")) {
			blockInfos = new ArrayList<BlockInfo>();
			int block_count = (int) Float.parseFloat(map.get("block_count").toString());
			Map blocks = (Map) map.get("blocks");
			for (int index = 0; index < block_count; index++) {
				int read = (int) Float.parseFloat(blocks.get("b" + index).toString());
				int _time = (int) Float.parseFloat(blocks.get("t" + index).toString());
				int _percent = (int) Float.parseFloat(blocks.get("p" + index).toString());
				blockInfos.add(new BlockInfo(index, read, _time, _percent));
			}
		}
		return blockInfos;
	}%>
	<%!public Map<String, Object> exportToBlockInfo(List<BlockInfo> blockInfos) {
		if (blockInfos == null)
			return null;
		Map<String, Object> blockInfoMap = null;
		int block_count = blockInfos.size();
		if (block_count <= 0) {
			return blockInfoMap;
		} else {
			blockInfoMap = new HashMap<String, Object>();
		}
		Map<String, Object> blocks = new HashMap<String, Object>();
		for (int index = 0; index < block_count; index++) {
			BlockInfo bi = blockInfos.get(index);
			int idx = bi.getIndex();
			blocks.put("b" + idx, bi.isReadBlock() ? 1 : 0);
			blocks.put("t" + idx, bi.getTime());
			blocks.put("p" + idx, bi.getPercent());
		}
		blockInfoMap.put("block_count", block_count);
		blockInfoMap.put("blocks", blocks);

		return blockInfoMap;
	}%>
	<%!public boolean isContainBlock(List<BlockInfo> blocks, int idx) {
		if (blocks != null) {
			for (BlockInfo block : blocks) {
				if (block.getIndex() == idx)
					return true;
			}
		}
		return false;
	}%>
	<%!public BlockInfo getBlock(List<BlockInfo> blocks, int idx) {
		if (blocks != null) {
			for (BlockInfo block : blocks) {
				if (block.getIndex() == idx)
					return block;
			}
		}
		return null;
	}%>
	<%
		final String dbPath = "D:\\lms.db";
		final String createUser = "CREATE TABLE IF NOT EXISTS users( id INTEGER PRIMARY KEY,  client_user_id VARCHAR(32) NOT NULL	);";
		final String createVideo = "CREATE TABLE IF NOT EXISTS videos ( id INTEGER PRIMARY KEY, media_content_key VARCHAR(32)	);";
		final String createProgressRelations = "CREATE TABLE IF NOT EXISTS progress_relations\r\n" + "(\r\n"
				+ "id INTEGER PRIMARY KEY,\r\n" + "video_id INT NOT NULL,\r\n" + "user_id INT NOT NULL,\r\n"
				+ "progress_block_info TEXT DEFAULT '',\r\n" + "progress_values FLOAT DEFAULt 0,\r\n"
				+ "start_at INT,\r\n" + "updated_at INT,\r\n"
				+ "CONSTRAINT callback_relations_user_id_fk FOREIGN KEY (user_id) REFERENCES users (id),\r\n"
				+ "CONSTRAINT callback_relations_video_id_fk FOREIGN KEY (video_id) REFERENCES videos (id)\r\n"
				+ ");";
		final String createIndex = "CREATE UNIQUE INDEX  IF NOT EXISTS progress_relations_video_id_user_id_uindex ON progress_relations (video_id DESC, user_id DESC);";
		final String createProgressDatas = "CREATE TABLE IF NOT EXISTS progress_datas\r\n" + "(\r\n"
				+ "  id INTEGER PRIMARY KEY,\r\n" + "  progress_relation_id INTEGER,\r\n" + "  start_at INT,\r\n"
				+ "  progress_block_info TEXT DEFAULT '',\r\n" + "  playtime INT DEFAULT 0,\r\n"
				+ "  player_id TEXT,\r\n" + "  device_name VARCHAR(255),\r\n" + "  updated_at INT,\r\n"
				+ "  CONSTRAINT progress_datas_progress_relations_id_fk FOREIGN KEY (progress_relation_id) REFERENCES progress_relations (id)\r\n"
				+ ");";
		final String insertUser = "INSERT INTO users (client_user_id) VALUES ('%s')";
		final String insertVideo = "INSERT INTO videos (media_content_key) VALUES('%s')";
		final String insertProgressRelations = "INSERT INTO progress_relations (video_id, user_id) VALUES ('%s', '%s')";
		final String insertProgressDatas = "INSERT INTO progress_datas (progress_relation_id, start_at, progress_block_info, playtime, player_id, device_name, updated_at) VALUES "
				+ "(%d, %d, '%s', %d, '%s', '%s', %d)";
		final String updateProgressRelations = "UPDATE progress_relations SET progress_block_info = '%s', progress_values = %d, start_at = %d, updated_at = %d WHERE id = %d";
		final String updateProgressDatas = "UPDATE progress_datas SET progress_block_info = '%s', playtime = %d, player_id='%s', updated_at=%d WHERE progress_relation_id = %d AND start_at=%d";
		final String selectUser = "SELECT * FROM users WHERE client_user_id = '%s'";
		final String selectVideo = "SELECT * FROM videos WHERE media_content_key = '%s'";
		final String selectProgressRelations = "SELECT * FROM progress_relations WHERE video_id = '%s' AND user_id = '%s'";
		final String selectProgressDatas = "SELECT * FROM progress_datas WHERE progress_relation_id = %d AND start_at = %d";
	%>
	<%
		Connection connection = null;
		Statement statement = null;
		Class.forName("org.sqlite.JDBC");
		connection = DriverManager.getConnection("jdbc:sqlite:" + dbPath);
		statement = connection.createStatement();
		statement.executeUpdate(createUser);
		statement.executeUpdate(createVideo);
		statement.executeUpdate(createProgressRelations);
		statement.executeUpdate(createIndex);
		statement.executeUpdate(createProgressDatas);
	%>


	<%
		String jsonData = request.getParameter("json_data");
		Map<String, Object> item = new Gson().fromJson(jsonData, Map.class);
		Map<String, Object> userInfo = (Map<String, Object>) item.get("user_info");
		Map<String, Object> contentInfo = (Map<String, Object>) item.get("content_info");
		Map<String, Object> blockInfo = (Map<String, Object>) item.get("block_info");
		String client_user_id = userInfo.containsKey("client_user_id") ? userInfo.get("client_user_id").toString()
				: null;
		String device_name = userInfo.containsKey("device_name") ? userInfo.get("device_name").toString() : "";
		String playerid = userInfo.containsKey("player_id") ? userInfo.get("player_id").toString() : null;
		String media_content_key = contentInfo.containsKey("media_content_key")
				? contentInfo.get("media_content_key").toString() : null;
		int start_at = contentInfo.containsKey("start_at")
				? Integer.parseInt(contentInfo.get("start_at").toString()) : 0;
		int playtime = contentInfo.containsKey("playtime")
				? Integer.parseInt(contentInfo.get("playtime").toString()) : 0;

		int progressRelationId = 0;
		List<BlockInfo> oldBlocks = null;
		ResultSet rs = null;
		rs = statement.executeQuery(String.format(selectUser, client_user_id));
		if (!rs.isBeforeFirst()) {
			statement.executeUpdate(String.format(insertUser, client_user_id));
		}
		rs = null;
		rs = statement.executeQuery(String.format(selectVideo, media_content_key));
		if (!rs.isBeforeFirst()) {
			statement.executeUpdate(String.format(insertVideo, media_content_key));
		}
		rs = null;
		rs = statement.executeQuery(String.format(selectProgressRelations, media_content_key, client_user_id));
		if (!rs.isBeforeFirst()) {
			statement.executeUpdate(String.format(insertProgressRelations, media_content_key, client_user_id));
			rs = statement.executeQuery(String.format(selectProgressRelations, media_content_key, client_user_id));
		}

		if (rs.next()) {
			String str_progress_block_info = rs.getString("progress_block_info");
			Map<String, Object> progress_block_info = null;
			progressRelationId = rs.getInt("id");
			if (!str_progress_block_info.isEmpty()) {
				progress_block_info = new Gson().fromJson(str_progress_block_info, Map.class);
				oldBlocks = importFromMap(progress_block_info);
			} else {
				oldBlocks = importFromMap(blockInfo);

			}
		}

		rs = null;
		rs = statement.executeQuery(String.format(selectProgressDatas, progressRelationId, start_at));
		if (!rs.isBeforeFirst()) {
			/*(progress_relation_id, start_at, progress_block_info, playtime, player_id, device_name, update_at)*/
			String query = String.format(insertProgressDatas, progressRelationId, start_at,
					new Gson().toJson(blockInfo), playtime, playerid, device_name, new Date().getTime());
			statement.executeUpdate(query);
		} else {
			/*progress_block_info = '%s', playtime = %d, player_id='%s', updated_at=%d WHERE progress_relation_id = %d AND start_at=%d*/
			statement.executeUpdate(String.format(updateProgressDatas, new Gson().toJson(blockInfo), playtime,
					playerid, new Date().getTime(), progressRelationId, start_at));
		}
		List<BlockInfo> newBlocks = importFromMap(blockInfo);
		List<BlockInfo> updateBlocks = new ArrayList<BlockInfo>();
		for (BlockInfo newblock : newBlocks) {
			BlockInfo updateBlock = null;
			BlockInfo oldBlock = getBlock(oldBlocks, newblock.getIndex());
			if (!isContainBlock(oldBlocks, newblock.getIndex())) {
				updateBlock = new BlockInfo();
			} else {
				updateBlock = oldBlock;
			}
			if (newblock.isReadBlock()) {
				updateBlock.setIsReadBlock(true);
			}
			if (oldBlock.getTime() < newblock.getTime()) {
				updateBlock.setTime(newblock.getTime());
			}
			if (oldBlock.getPercent() < newblock.getPercent()) {
				updateBlock.setPercent(newblock.getPercent());
			}
			updateBlocks.add(updateBlock);
		}
		int update_is_read_block = 0;
		for (BlockInfo block : updateBlocks) {
			if (block.is_read_block)
				update_is_read_block++;
		}
		int progressValue = updateBlocks.size() > 0 ? update_is_read_block / updateBlocks.size() : 0;
		/*progress_block_info = %s, progress_values=%s, start_at=%d, update_at=%d WHERE id = %d*/
		String query = String.format(updateProgressRelations, new Gson().toJson(exportToBlockInfo(updateBlocks)),
				progressValue, start_at, new Date().getTime(), progressRelationId);
		statement.executeUpdate(query);
		rs.close();
		statement.close();
		connection.close();
		response.setStatus(200);
	%>

</body>
</html>