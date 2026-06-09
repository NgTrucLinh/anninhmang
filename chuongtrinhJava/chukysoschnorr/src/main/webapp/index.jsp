<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.Map" %>
<%
    boolean hasKeys = (request.getAttribute("publicKey") != null
        && !request.getAttribute("publicKey").toString().isEmpty());

    @SuppressWarnings("unchecked")
    Map<String,String> fieldErrors = (Map<String,String>) request.getAttribute("fieldErrors");

    String verifyStatus = request.getAttribute("verifyStatus") != null
        ? request.getAttribute("verifyStatus").toString() : "";
    String verifyDetail = request.getAttribute("verifyDetail") != null
        ? request.getAttribute("verifyDetail").toString() : "";

    int selPBits = request.getAttribute("selectedPBits") != null
        ? (int) request.getAttribute("selectedPBits") : 512;
    int selQBits = request.getAttribute("selectedQBits") != null
        ? (int) request.getAttribute("selectedQBits") : 160;
%>
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Schnorr Digital Signature</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Mono:wght@400;500&family=Plus+Jakarta+Sans:wght@400;500;600&display=swap" rel="stylesheet">
<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}

:root{
  --bg:       #eef1f7;
  --surface:  #ffffff;
  --surface2: #f4f6fb;
  --border:   #dde3ef;
  --border2:  #c8d2e6;
  --text:     #1c2333;
  --text2:    #4a5572;
  --text3:    #8a97b0;
  --accent:   #4361ee;
  --accent-l: #eef0fd;
  --accent-h: #2f4bd4;
  --ok:       #16a34a;
  --ok-l:     #f0fdf4;
  --ok-b:     #bbf7d0;
  --err:      #dc2626;
  --err-l:    #fef2f2;
  --err-b:    #fecaca;
  --warn:     #b45309;
  --warn-l:   #fffbeb;
  --warn-b:   #fde68a;
  --info:     #1d4ed8;
  --info-l:   #eff6ff;
  --info-b:   #bfdbfe;
  --mono:     'IBM Plex Mono', monospace;
  --sans:     'Plus Jakarta Sans', sans-serif;
  --r:        10px;
  --rs:       6px;
}

html, body {
  font-family: var(--sans);
  font-size: 13.5px;
  line-height: 1.55;
  background: var(--bg);
  color: var(--text);
  /* KHÔNG giới hạn height — cho phép trang cuộn tự do */
}

/* ── LAYOUT ── */
.app {
  padding: 12px;
  display: flex;
  flex-direction: column;
  gap: 10px;
  min-height: 100vh;
}

/* ── TOPBAR ── */
.topbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: var(--r);
  padding: 10px 16px;
  gap: 12px;
  flex-wrap: wrap;
  position: sticky;
  top: 12px;
  z-index: 100;
  box-shadow: 0 2px 8px rgba(0,0,0,.06);
}
.logo { display:flex;align-items:center;gap:10px }
.logo-icon {
  width:34px;height:34px;background:var(--accent);
  border-radius:8px;display:flex;align-items:center;
  justify-content:center;color:#fff;font-size:17px;flex-shrink:0;
}
.logo-name { font-size:15px;font-weight:600;color:var(--text) }
.logo-sub  { font-size:11px;color:var(--text3);font-family:var(--mono);margin-top:1px }
.topbar-right { display:flex;align-items:center;gap:12px;flex-wrap:wrap }
.key-status { display:flex;align-items:center;gap:7px }
.status-dot {
  width:8px;height:8px;border-radius:50%;
  background:<%= hasKeys ? "var(--ok)" : "var(--text3)" %>;
  box-shadow:<%= hasKeys ? "0 0 0 3px var(--ok-l)" : "none" %>;
}
.status-label {
  font-size:12px;font-family:var(--mono);
  color:<%= hasKeys ? "var(--ok)" : "var(--text3)" %>;
}

/* ── PAGE ALERTS ── */
.page-alert {
  display:flex;align-items:flex-start;gap:8px;
  padding:9px 12px;border-radius:var(--rs);
  font-size:12.5px;line-height:1.5;
}
.page-alert.ok  { background:var(--ok-l);border:1px solid var(--ok-b);color:var(--ok) }
.page-alert.err { background:var(--err-l);border:1px solid var(--err-b);color:var(--err) }

/* ── 3-COLUMN GRID — cuộn tự do theo nội dung ── */
.cols {
  display: grid;
  grid-template-columns: 1fr 1fr 1fr;
  gap: 10px;
  align-items: start;   /* mỗi cột cao theo nội dung, không bị kéo dài */
}

/* ── COLUMN ── */
.col {
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: var(--r);
  display: flex;
  flex-direction: column;
  overflow: visible;    /* không cắt nội dung */
}
.col-head {
  padding:10px 14px;
  background:var(--surface2);
  border-bottom:1px solid var(--border);
  border-radius: var(--r) var(--r) 0 0;
  display:flex;align-items:center;justify-content:space-between;
  gap:8px;
  position: sticky;
  top: 70px;            /* dính dưới topbar khi cuộn */
  z-index: 10;
}
.col-head-l { display:flex;align-items:center;gap:8px }
.step-num {
  width:22px;height:22px;border-radius:50%;
  background:var(--accent);color:#fff;
  font-size:11.5px;font-weight:600;
  display:flex;align-items:center;justify-content:center;
  font-family:var(--mono);flex-shrink:0;
}
.col-title { font-size:13.5px;font-weight:600;color:var(--text) }
.col-body {
  padding:12px;
  display:flex;flex-direction:column;gap:10px;
  /* KHÔNG overflow:hidden, KHÔNG max-height — hiển thị hết nội dung */
}

/* ── SECTION BOX ── */
.section-box {
  border: 1.5px solid var(--border2);
  border-radius: var(--r);
  overflow: hidden;
  background: var(--surface);
}
.section-box-head {
  padding: 9px 14px;
  background: linear-gradient(90deg,var(--surface2) 0%,var(--surface) 100%);
  border-bottom: 1.5px solid var(--border2);
  font-size: 12.5px;font-weight:600;color:var(--text2);
  display:flex;align-items:center;justify-content:space-between;gap:8px;
  letter-spacing:.1px;
}
.section-box-head .sec-icon { font-size:15px;margin-right:4px }
.section-box-body {
  padding: 12px 14px;
  display:flex;flex-direction:column;gap:10px;
}

/* ── FORM ── */
.lbl {
  display:block;font-size:11px;font-weight:600;
  color:var(--text2);text-transform:uppercase;
  letter-spacing:.4px;margin-bottom:4px;
}
input[type=text], textarea, select {
  width:100%;background:var(--surface);
  border:1px solid var(--border);border-radius:var(--rs);
  color:var(--text);font-family:var(--mono);font-size:11.5px;
  padding:7px 10px;outline:none;transition:border-color .15s;resize:none;
}
input:focus, textarea:focus, select:focus {
  border-color:var(--accent);box-shadow:0 0 0 3px var(--accent-l)
}
textarea { min-height:70px; }
select { font-family:var(--sans);cursor:pointer }

/* ── INPUT LỖI ── */
.input-err { border-color:var(--err)!important;background:#fff5f5!important }
.input-err:focus { box-shadow:0 0 0 3px var(--err-l)!important }
.field-err-msg {
  margin-top:4px;font-size:11px;color:var(--err);
  background:var(--err-l);border:1px solid var(--err-b);
  border-radius:4px;padding:4px 8px;line-height:1.5;
}

/* ── FILE INPUT ── */
.file-wrap {
  border:1.5px dashed var(--border2);border-radius:var(--rs);
  padding:9px 12px;display:flex;align-items:center;gap:8px;
  cursor:pointer;transition:border-color .15s;background:var(--surface);
}
.file-wrap:hover { border-color:var(--accent) }
.file-wrap input { display:none }
.file-wrap-text  { font-size:12px;color:var(--text2) }
.file-wrap-text b { color:var(--accent);font-weight:500 }
.file-wrap-hint { font-size:10.5px;color:var(--text3);margin-top:2px }
.file-chosen { font-size:11px;color:var(--ok);font-family:var(--mono);margin-top:3px }

/* ── DIVIDER ── */
.or { display:flex;align-items:center;gap:8px;color:var(--text3);font-size:11.5px }
.or::before,.or::after { content:'';flex:1;height:1px;background:var(--border) }

/* ── BUTTONS ── */
.btn {
  display:inline-flex;align-items:center;justify-content:center;
  gap:6px;border:none;border-radius:var(--rs);
  font-family:var(--sans);font-size:12.5px;font-weight:500;
  padding:8px 14px;cursor:pointer;transition:all .15s;
  text-decoration:none;white-space:nowrap;
}
.btn-primary   { background:var(--accent);color:#fff }
.btn-primary:hover { background:var(--accent-h) }
.btn-secondary { background:var(--surface);color:var(--text);border:1px solid var(--border2) }
.btn-secondary:hover { border-color:var(--accent);color:var(--accent) }
.btn-danger    { background:var(--err-l);color:var(--err);border:1px solid var(--err-b) }
.btn-danger:hover  { background:#fee2e2 }
.btn-ghost {
  background:transparent;color:var(--text2);border:none;
  padding:4px 8px;font-size:11.5px;cursor:pointer;border-radius:var(--rs);
}
.btn-ghost:hover { background:var(--border);color:var(--text) }
.btn-xs  { padding:5px 10px;font-size:12px }
.btn-row { display:flex;align-items:center;gap:8px;flex-wrap:wrap }
.hint    { font-size:11.5px;color:var(--text3);line-height:1.5 }

/* ── BIT SELECTOR ── */
.bit-selector { display:grid;grid-template-columns:1fr 1fr;gap:8px }

/* ── KEY BOXES ── */
.key-grid { display:grid;grid-template-columns:1fr 1fr;gap:8px }
.kbox     { border-radius:var(--rs);padding:8px 10px }
.kbox-priv { background:var(--warn-l);border:1px solid var(--warn-b) }
.kbox-pub  { background:var(--info-l);border:1px solid var(--info-b) }
.kbox-lbl  { font-size:10.5px;font-weight:600;text-transform:uppercase;letter-spacing:.3px;margin-bottom:5px }
.kbox-priv .kbox-lbl { color:var(--warn) }
.kbox-pub  .kbox-lbl { color:var(--info) }
.kbox-val  { font-family:var(--mono);font-size:10.5px;color:var(--text);word-break:break-all;line-height:1.7 }
.kbox-priv input[type=text] {
  background:transparent;border:none;
  border-bottom:1px solid var(--warn-b);
  border-radius:0;padding:3px 0;
  font-size:11px;color:var(--text);box-shadow:none;
}
.kbox-priv input:focus { border-bottom-color:var(--warn);box-shadow:none }

/* ── SIGNATURE OUTPUT ── */
.sig-field { padding:8px 12px;border-bottom:1px solid var(--ok-b) }
.sig-field:last-child { border-bottom:none }
.sig-field-lbl {
  font-size:10.5px;font-weight:600;color:var(--text2);
  text-transform:uppercase;letter-spacing:.3px;margin-bottom:4px;
  display:flex;align-items:center;justify-content:space-between;
}
.sig-field-val { font-family:var(--mono);font-size:11px;color:var(--text);word-break:break-all;line-height:1.7 }

/* ── COPY TO VERIFY ── */
.c2v {
  background:var(--accent-l);border:1px solid #c7d2fc;
  border-radius:var(--rs);padding:8px 11px;
  display:flex;align-items:center;justify-content:space-between;gap:8px;flex-wrap:wrap;
}
.c2v span { font-size:12px;color:var(--text2) }

/* ── VERIFY RESULT — THÔNG BÁO CHI TIẾT ── */
.vr-box {
  border-radius: var(--r);
  overflow: hidden;
}
.vr-box-ok  { border: 1.5px solid var(--ok-b) }
.vr-box-err { border: 1.5px solid var(--err-b) }

.vr-banner {
  padding: 12px 14px;
  display: flex;
  align-items: center;
  gap: 12px;
}
.vr-banner-ok  { background: var(--ok-l) }
.vr-banner-err { background: var(--err-l) }

.vr-icon {
  width:42px;height:42px;border-radius:50%;
  display:flex;align-items:center;justify-content:center;
  font-size:22px;flex-shrink:0;font-weight:700;
}
.vr-icon-ok  { background:#dcfce7;color:var(--ok) }
.vr-icon-err { background:#fee2e2;color:var(--err) }

.vr-title { font-size:14px;font-weight:700;margin-bottom:2px }
.vr-title-ok  { color:var(--ok) }
.vr-title-err { color:var(--err) }
.vr-subtitle  { font-size:12px;color:var(--text2) }

/* Khung chi tiết nguyên nhân */
.vr-cause {
  border-top: 1.5px solid var(--err-b);
  padding: 10px 14px;
  display: flex;
  flex-direction: column;
  gap: 6px;
  background: #fff9f9;
}
.vr-cause-title {
  font-size: 11.5px;font-weight:700;color:var(--err);
  display:flex;align-items:center;gap:5px;
}
.vr-cause-row {
  display: flex;
  align-items: flex-start;
  gap: 8px;
  padding: 6px 10px;
  border-radius: var(--rs);
  font-size: 12px;
  line-height: 1.6;
}
/* Lỗi văn bản */
.vr-cause-msg  { background: #fff3e0;border:1px solid #fcd9a0;color:#7c4a00 }
/* Lỗi chữ ký */
.vr-cause-sig  { background: #fef2f2;border:1px solid var(--err-b);color:#991b1b }
/* Lỗi định dạng */
.vr-cause-fmt  { background: #fdf2f8;border:1px solid #f0abda;color:#86198f }

.vr-cause-icon { font-size:15px;flex-shrink:0;margin-top:1px }
.vr-cause-text strong { font-weight:700 }

/* ── COPY FEEDBACK ── */
.cf { font-size:10.5px;color:var(--ok);opacity:0;transition:opacity .3s;margin-left:4px }
.cf.show { opacity:1 }

/* ── RESPONSIVE ── */
@media(max-width:900px){
  .cols { grid-template-columns:1fr }
  .col-head { position:static }
  .topbar { position:static }
  .key-grid { grid-template-columns:1fr }
  .bit-selector { grid-template-columns:1fr }
}
</style>
</head>
<body>
<div class="app">

  <!-- TOPBAR -->
  <header class="topbar">
    <div class="logo">
      <div class="logo-icon">🔐</div>
      <div>
        <div class="logo-name">Schnorr Digital Signature</div>
        <div class="logo-sub">Jakarta EE 11 · Tomcat 11 · SHA-256</div>
      </div>
    </div>
    <div class="topbar-right">
      <% if (request.getAttribute("error") != null) { %>
      <div class="page-alert err">⚠ ${error}</div>
      <% } %>
      <% if (request.getAttribute("successMsg") != null) { %>
      <div class="page-alert ok">✓ ${successMsg}</div>
      <% } %>
      <div class="key-status">
        <div class="status-dot"></div>
        <span class="status-label"><%= hasKeys ? "Khóa đã sẵn sàng" : "Chưa có khóa" %></span>
      </div>
    </div>
  </header>

  <!-- 3 COLUMNS -->
  <div class="cols">

    <!-- ══════════════ COL 1: KHỞI TẠO KHÓA ══════════════ -->
    <div class="col">
      <div class="col-head">
        <div class="col-head-l">
          <div class="step-num">1</div>
          <span class="col-title">Khởi tạo khóa</span>
        </div>
        <form action="schnorr?action=reset" method="post" style="margin:0">
          <button type="submit" class="btn btn-danger btn-xs"
                  onclick="return confirm('Đặt lại sẽ xóa toàn bộ dữ liệu khóa. Tiếp tục?')">
            ↺ Đặt lại
          </button>
        </form>
      </div>
      <div class="col-body">

        <!-- KHUNG: Sinh khóa tự động -->
        <div class="section-box">
          <div class="section-box-head">
            <span><span class="sec-icon">🎲</span> Sinh khóa tự động</span>
          </div>
          <div class="section-box-body">
            <p class="hint">Tự động tạo nhóm Schnorr và cặp khóa ngẫu nhiên an toàn theo kích thước bit bạn chọn.</p>
            <form action="schnorr?action=generateKeys" method="post">
              <div style="display:flex;flex-direction:column;gap:9px">
                <div class="bit-selector">
                  <div>
                    <label class="lbl">Kích thước p (bit)</label>
                    <select name="pBits">
                      <option value="512"  <%= selPBits==512  ? "selected":"" %>>512 bit — Nhanh</option>
                      <option value="1024" <%= selPBits==1024 ? "selected":"" %>>1024 bit — Chuẩn</option>
                      <option value="2048" <%= selPBits==2048 ? "selected":"" %>>2048 bit — Mạnh</option>
                    </select>
                  </div>
                  <div>
                    <label class="lbl">Kích thước q (bit)</label>
                    <select name="qBits">
                      <option value="160" <%= selQBits==160 ? "selected":"" %>>160 bit</option>
                      <option value="224" <%= selQBits==224 ? "selected":"" %>>224 bit</option>
                      <option value="256" <%= selQBits==256 ? "selected":"" %>>256 bit</option>
                    </select>
                  </div>
                </div>
                <p class="hint">⚠ p càng lớn thì sinh khóa càng lâu (2048-bit có thể mất vài giây).</p>
                <button type="submit" class="btn btn-primary">⚡ Tự động sinh bộ khóa</button>
              </div>
            </form>
          </div>
        </div>

        <!-- KHUNG: Nhập thủ công -->
        <div class="section-box">
          <div class="section-box-head">
            <span><span class="sec-icon">⚙</span> Nhập tham số &amp; khóa thủ công (HEX)</span>
            <% if (hasKeys) { %>
            <button class="btn-ghost btn-xs" onclick="copyAllKeys()">⎘ Copy tất cả<span class="cf" id="cfAll"></span></button>
            <% } %>
          </div>
          <div class="section-box-body">
            <form action="schnorr?action=setKeys" method="post">
              <div style="display:flex;flex-direction:column;gap:10px">

                <div>
                  <label class="lbl">Modulus p — số nguyên tố lớn</label>
                  <input type="text" name="p" value="${pHex}" placeholder="Nhập giá trị HEX của p..."
                    class="<%= (fieldErrors!=null&&fieldErrors.containsKey("p"))?"input-err":"" %>">
                  <% if (fieldErrors!=null&&fieldErrors.containsKey("p")) { %>
                  <div class="field-err-msg">⚠ <%= fieldErrors.get("p") %></div>
                  <% } %>
                </div>

                <div>
                  <label class="lbl">Bậc q — số nguyên tố nhỏ (q | p−1)</label>
                  <input type="text" name="q" value="${qHex}" placeholder="Nhập giá trị HEX của q..."
                    class="<%= (fieldErrors!=null&&fieldErrors.containsKey("q"))?"input-err":"" %>">
                  <% if (fieldErrors!=null&&fieldErrors.containsKey("q")) { %>
                  <div class="field-err-msg">⚠ <%= fieldErrors.get("q") %></div>
                  <% } %>
                </div>

                <div>
                  <label class="lbl">Bộ sinh g &nbsp;(g<sup>q</sup> ≡ 1 mod p)</label>
                  <input type="text" name="g" value="${gHex}" placeholder="Nhập giá trị HEX của g..."
                    class="<%= (fieldErrors!=null&&fieldErrors.containsKey("g"))?"input-err":"" %>">
                  <% if (fieldErrors!=null&&fieldErrors.containsKey("g")) { %>
                  <div class="field-err-msg">⚠ <%= fieldErrors.get("g") %></div>
                  <% } %>
                </div>

                <div class="key-grid">
                  <div class="kbox kbox-priv">
                    <div class="kbox-lbl">🔑 Khóa bí mật (x)</div>
                    <input type="text" name="privateKey" value="${privateKey}" placeholder="Nhập x (HEX)..."
                      class="<%= (fieldErrors!=null&&fieldErrors.containsKey("x"))?"input-err":"" %>">
                    <% if (fieldErrors!=null&&fieldErrors.containsKey("x")) { %>
                    <div class="field-err-msg" style="margin-top:5px">⚠ <%= fieldErrors.get("x") %></div>
                    <% } %>
                  </div>
                  <div class="kbox kbox-pub">
                    <div class="kbox-lbl">🌐 Khóa công khai (y)</div>
                    <div class="kbox-val">${not empty publicKey ? publicKey : '— chưa có —'}</div>
                  </div>
                </div>

                <div class="btn-row">
                  <button type="submit" class="btn btn-secondary">✓ Áp dụng thủ công</button>
                  <span class="hint">Mỗi tham số được kiểm tra riêng trước khi lưu.</span>
                </div>
              </div>
            </form>
          </div>
        </div>

      </div>
    </div><!-- end col 1 -->


    <!-- ══════════════ COL 2: KÝ VĂN BẢN ══════════════ -->
    <div class="col">
      <div class="col-head">
        <div class="col-head-l">
          <div class="step-num">2</div>
          <span class="col-title">Ký văn bản</span>
        </div>
      </div>
      <div class="col-body">

        <% if (!hasKeys) { %>
        <div class="page-alert err">ℹ Chưa có khóa. Vui lòng hoàn thành Bước 1 trước.</div>
        <% } %>

        <!-- KHUNG: Khóa đang dùng -->
        <% if (hasKeys) { %>
        <div class="section-box">
          <div class="section-box-head">
            <span><span class="sec-icon">🔑</span> Khóa đang sử dụng</span>
          </div>
          <div class="section-box-body" style="padding:10px 14px">
            <div class="key-grid">
              <div class="kbox kbox-priv">
                <div class="kbox-lbl">Bí mật (x)</div>
                <div class="kbox-val">${privateKey}</div>
              </div>
              <div class="kbox kbox-pub">
                <div class="kbox-lbl">Công khai (y)</div>
                <div class="kbox-val">${publicKey}</div>
              </div>
            </div>
          </div>
        </div>
        <% } %>

        <!-- KHUNG: Tạo chữ ký -->
        <div class="section-box">
          <div class="section-box-head">
            <span><span class="sec-icon">✍</span> Tạo chữ ký số</span>
          </div>
          <div class="section-box-body">
            <form action="schnorr?action=sign" method="post" enctype="multipart/form-data">
              <div style="display:flex;flex-direction:column;gap:9px">
                <div>
                  <label class="lbl">Cách 1 — Tải file lên</label>
                  <label class="file-wrap" for="signFileTxt">
                    <span style="font-size:18px">📄</span>
                    <div class="file-wrap-text">
                      <b>Chọn file</b> hoặc kéo thả vào đây
                      <div class="file-wrap-hint">Hỗ trợ: .txt · .xlsx · .xls · .docx · .doc · Tối đa 10 MB</div>
                    </div>
                    <input type="file" id="signFileTxt" name="fileTxt"
                           accept=".txt,.xlsx,.xls,.docx,.doc"
                           onchange="updateFileName(this,'signFileChosen')">
                  </label>
                  <div class="file-chosen" id="signFileChosen"></div>
                </div>
                <div class="or">hoặc</div>
                <div>
                  <label class="lbl">Cách 2 — Nhập văn bản trực tiếp</label>
                  <textarea name="message" placeholder="Nhập nội dung cần ký vào đây...">${signedMessage}</textarea>
                </div>
                <button type="submit" class="btn btn-primary"
                  <%= !hasKeys?"disabled style='opacity:.5;cursor:not-allowed'":"" %>>
                  🖊 Thực hiện ký số
                </button>
              </div>
            </form>
          </div>
        </div>

        <!-- KHUNG: Kết quả chữ ký -->
        <% if (request.getAttribute("sigE") != null) { %>
        <div class="section-box">
          <div class="section-box-head" style="color:var(--ok);background:linear-gradient(90deg,#f0fdf4,#fff)">
            <span><span class="sec-icon">✅</span> Kết quả — Chữ ký đã tạo</span>
            <button class="btn-ghost btn-xs" onclick="copySig()" style="color:var(--ok)">
              ⎘ Copy (e, s)<span class="cf" id="cfSig"></span>
            </button>
          </div>
          <div class="section-box-body" style="padding:0;background:var(--ok-l)">
            <div class="sig-field">
              <div class="sig-field-lbl">
                Thành phần băm e
                <button class="btn-ghost" onclick="copyText('${sigE}','cfE')" style="font-size:11px">
                  ⎘<span class="cf" id="cfE"></span>
                </button>
              </div>
              <div class="sig-field-val" id="outSigE">${sigE}</div>
            </div>
            <div class="sig-field">
              <div class="sig-field-lbl">
                Thành phần chứng thực s
                <button class="btn-ghost" onclick="copyText('${sigS}','cfS')" style="font-size:11px">
                  ⎘<span class="cf" id="cfS"></span>
                </button>
              </div>
              <div class="sig-field-val" id="outSigS">${sigS}</div>
            </div>
          </div>
        </div>
        <div class="c2v">
          <span>Muốn xác minh ngay chữ ký vừa tạo?</span>
          <button class="btn btn-secondary btn-xs"
                  onclick="goVerify('${sigE}','${sigS}',`${signedMessage}`)">
            → Chuyển sang xác minh
          </button>
        </div>
        <% } %>

      </div>
    </div><!-- end col 2 -->


    <!-- ══════════════ COL 3: XÁC MINH ══════════════ -->
    <div class="col">
      <div class="col-head">
        <div class="col-head-l">
          <div class="step-num">3</div>
          <span class="col-title">Xác minh chữ ký</span>
        </div>
      </div>
      <div class="col-body">

        <% if (!hasKeys) { %>
        <div class="page-alert err">ℹ Chưa có khóa công khai. Vui lòng hoàn thành Bước 1 trước.</div>
        <% } %>

        <!-- KHUNG: Nhập dữ liệu xác minh -->
        <div class="section-box">
          <div class="section-box-head">
            <span><span class="sec-icon">🔍</span> Nhập dữ liệu xác minh</span>
          </div>
          <div class="section-box-body">
            <form action="schnorr?action=verify" method="post" enctype="multipart/form-data">
              <div style="display:flex;flex-direction:column;gap:9px">
                <div>
                  <label class="lbl">Cách 1 — Tải file gốc lên</label>
                  <label class="file-wrap" for="verifyFileTxt">
                    <span style="font-size:18px">📄</span>
                    <div class="file-wrap-text">
                      <b>Chọn file</b> hoặc kéo thả vào đây
                      <div class="file-wrap-hint">Hỗ trợ: .txt · .xlsx · .xls · .docx · .doc · Tối đa 10 MB</div>
                    </div>
                    <input type="file" id="verifyFileTxt" name="verifyFileTxt"
                           accept=".txt,.xlsx,.xls,.docx,.doc"
                           onchange="updateFileName(this,'verifyFileChosen')">
                  </label>
                  <div class="file-chosen" id="verifyFileChosen"></div>
                </div>
                <div class="or">hoặc</div>
                <div>
                  <label class="lbl">Cách 2 — Dán nội dung văn bản gốc</label>
                  <textarea name="verifyMessage" id="verifyMsgArea"
                            placeholder="Dán nội dung văn bản gốc...">${verifyMessage}</textarea>
                </div>
                <div class="key-grid">
                  <div>
                    <label class="lbl">Chữ ký e (HEX)</label>
                    <input type="text" name="sigE" id="verifyE" value="${verifyE}" placeholder="Dán giá trị e...">
                  </div>
                  <div>
                    <label class="lbl">Chữ ký s (HEX)</label>
                    <input type="text" name="sigS" id="verifyS" value="${verifyS}" placeholder="Dán giá trị s...">
                  </div>
                </div>
                <button type="submit" class="btn btn-primary"
                  <%= !hasKeys?"disabled style='opacity:.5;cursor:not-allowed'":"" %>>
                  🔍 Bắt đầu xác minh
                </button>
              </div>
            </form>
          </div>
        </div>

        <!-- KHUNG: Kết quả xác minh — PHÂN BIỆT RÕ TỪNG LOẠI LỖI -->
        <% if (request.getAttribute("verifyResult") != null) {
               boolean isValid = (Boolean) request.getAttribute("verifyResult"); %>

        <div class="vr-box <%= isValid ? "vr-box-ok" : "vr-box-err" %>">

          <!-- Banner trạng thái chính -->
          <div class="vr-banner <%= isValid ? "vr-banner-ok" : "vr-banner-err" %>">
            <div class="vr-icon <%= isValid ? "vr-icon-ok" : "vr-icon-err" %>">
              <%= isValid ? "✓" : "✕" %>
            </div>
            <div>
              <div class="vr-title <%= isValid ? "vr-title-ok" : "vr-title-err" %>">
                <%= isValid ? "CHỮ KÝ HỢP LỆ" : "CHỮ KÝ KHÔNG HỢP LỆ" %>
              </div>
              <div class="vr-subtitle">
                <%= isValid
                    ? "Nội dung văn bản toàn vẹn. Chữ ký khớp với khóa công khai."
                    : "Xác minh thất bại. Xem chi tiết nguyên nhân bên dưới." %>
              </div>
            </div>
          </div>

          <%-- Phần chi tiết nguyên nhân — chỉ hiện khi thất bại --%>
          <% if (!isValid) { %>
          <div class="vr-cause">
            <div class="vr-cause-title">⚠ Nguyên nhân cụ thể</div>

            <%-- TRƯỜNG HỢP 1: Chữ ký e bị sai (phát hiện chính xác qua kiểm tra chéo) --%>
            <% if (verifyStatus.equals("INVALID_SIGNATURE_E")) { %>
            <div class="vr-cause-row vr-cause-sig">
              <span class="vr-cause-icon">🔢</span>
              <div class="vr-cause-text">
                <strong>Chữ ký e bị sai hoặc bị thay đổi</strong><br>
                Hệ thống xác định văn bản và giá trị <code>s</code> nhất quán với nhau,
                nhưng giá trị <code>e</code> không khớp.
                Hãy kiểm tra lại giá trị <code>e</code> đã copy đầy đủ và đúng chưa.
              </div>
            </div>

            <%-- TRƯỜNG HỢP 2: Chữ ký s bị sai phạm vi --%>
            <% } else if (verifyStatus.equals("INVALID_SIGNATURE_S")) { %>
            <div class="vr-cause-row vr-cause-sig">
              <span class="vr-cause-icon">🔢</span>
              <div class="vr-cause-text">
                <strong>Chữ ký s không hợp lệ</strong><br>
                Giá trị <code>s</code> nằm ngoài phạm vi cho phép [1, q−1].
                Hãy kiểm tra lại giá trị <code>s</code> đã copy đúng chưa.
              </div>
            </div>

            <%-- TRƯỜNG HỢP 3: Cả e và s đều sai phạm vi --%>
            <% } else if (verifyStatus.equals("INVALID_SIGNATURE_BOTH")) { %>
            <div class="vr-cause-row vr-cause-sig">
              <span class="vr-cause-icon">🔢</span>
              <div class="vr-cause-text">
                <strong>Cả hai giá trị e và s đều không hợp lệ</strong><br>
                Cả <code>e</code> lẫn <code>s</code> đều nằm ngoài phạm vi [1, q−1].
                Chữ ký có thể bị hỏng hoàn toàn hoặc không thuộc hệ thống này.
              </div>
            </div>

            <%-- TRƯỜNG HỢP 4: Cặp (e,s) không khớp — có thể cả 2 sai hoặc văn bản sai --%>
            <% } else if (verifyStatus.equals("INVALID_SIGNATURE_PAIR")) { %>
            <div class="vr-cause-row vr-cause-sig" style="margin-bottom:6px">
              <span class="vr-cause-icon">🔢</span>
              <div class="vr-cause-text">
                <strong>Cặp chữ ký (e, s) không hợp lệ với văn bản này</strong><br>
                Hệ thống không thể xác định chính xác phần nào bị sai.
                Có thể do một trong các nguyên nhân sau:
              </div>
            </div>
            <div class="vr-cause-row vr-cause-msg">
              <span class="vr-cause-icon">📝</span>
              <div class="vr-cause-text">
                <strong>Khả năng 1 — Nội dung văn bản bị thay đổi:</strong>
                văn bản bạn nhập khác với văn bản gốc lúc ký (thêm/xóa/sửa ký tự, thay đổi khoảng trắng).
              </div>
            </div>
            <div class="vr-cause-row vr-cause-sig">
              <span class="vr-cause-icon">🔑</span>
              <div class="vr-cause-text">
                <strong>Khả năng 2 — Chữ ký bị thay đổi:</strong>
                cả <code>e</code> và <code>s</code> đều bị sai hoặc không phải chữ ký của văn bản này.
              </div>
            </div>

            <%-- TRƯỜNG HỢP 5: Nội dung văn bản bị thay đổi (fallback cũ) --%>
            <% } else if (verifyStatus.equals("TAMPERED_MESSAGE")) { %>
            <div class="vr-cause-row vr-cause-msg">
              <span class="vr-cause-icon">📝</span>
              <div class="vr-cause-text">
                <strong>Nội dung văn bản có thể bị thay đổi</strong><br>
                Chữ ký (e, s) đúng định dạng nhưng không xác minh được với nội dung này.
                Hãy kiểm tra lại văn bản — có thể bị thêm/xóa/sửa ký tự.
              </div>
            </div>

            <%-- TRƯỜNG HỢP 6: Định dạng HEX sai --%>
            <% } else if (verifyStatus.equals("INVALID_FORMAT")) { %>
            <div class="vr-cause-row vr-cause-fmt">
              <span class="vr-cause-icon">❌</span>
              <div class="vr-cause-text">
                <strong>Định dạng chữ ký sai</strong><br>
                Giá trị e hoặc s không phải chuỗi HEX hợp lệ.
                Chỉ được chứa các ký tự <code>0-9</code> và <code>A-F</code>.
                Kiểm tra xem có khoảng trắng, dấu xuống dòng hay ký tự lạ không.
              </div>
            </div>

            <%-- Mặc định --%>
            <% } else { %>
            <div class="vr-cause-row vr-cause-msg">
              <span class="vr-cause-icon">⚠</span>
              <div class="vr-cause-text"><%= verifyDetail %></div>
            </div>
            <% } %>

          </div>
          <% } %>

        </div><!-- end vr-box -->
        <% } %>

      </div>
    </div><!-- end col 3 -->

  </div>
</div>

<script>
function updateFileName(input, targetId) {
  const el = document.getElementById(targetId);
  el.textContent = input.files[0] ? '📎 ' + input.files[0].name : '';
}

function copyText(text, feedId) {
  navigator.clipboard.writeText(text || '').then(() => {
    const el = document.getElementById(feedId);
    if (!el) return;
    el.textContent = ' Đã copy!';
    el.classList.add('show');
    setTimeout(() => el.classList.remove('show'), 1800);
  });
}

function copySig() {
  const e = document.getElementById('outSigE')?.textContent || '';
  const s = document.getElementById('outSigS')?.textContent || '';
  copyText('e: ' + e + '\ns: ' + s, 'cfSig');
}

function copyAllKeys() {
  const p = document.querySelector('input[name="p"]')?.value || '';
  const q = document.querySelector('input[name="q"]')?.value || '';
  const g = document.querySelector('input[name="g"]')?.value || '';
  const x = document.querySelector('input[name="privateKey"]')?.value || '';
  const y = document.querySelector('.kbox-pub .kbox-val')?.textContent?.trim() || '';
  navigator.clipboard.writeText('p: '+p+'\nq: '+q+'\ng: '+g+'\nx (private): '+x+'\ny (public): '+y).then(() => {
    const el = document.getElementById('cfAll');
    if (!el) return;
    el.textContent = ' Đã copy!';
    el.classList.add('show');
    setTimeout(() => el.classList.remove('show'), 1800);
  });
}

function goVerify(e, s, msg) {
  const eEl = document.getElementById('verifyE');
  const sEl = document.getElementById('verifyS');
  const mEl = document.getElementById('verifyMsgArea');
  if (eEl) eEl.value = e;
  if (sEl) sEl.value = s;
  if (mEl && msg && msg.trim()) mEl.value = msg;
  const col3 = document.querySelectorAll('.col')[2];
  if (col3) col3.scrollIntoView({ behavior:'smooth', block:'start' });
  if (eEl) eEl.focus();
}
</script>
</body>
</html>
