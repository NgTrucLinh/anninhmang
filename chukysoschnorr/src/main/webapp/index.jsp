<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    boolean hasKeys = (request.getAttribute("publicKey") != null
        && !request.getAttribute("publicKey").toString().isEmpty());
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

html,body{
  font-family:var(--sans);
  font-size:13.5px;
  line-height:1.55;
  background:var(--bg);
  color:var(--text);
  height:100%;
}

/* ── LAYOUT ── */
.app{
  display:grid;
  grid-template-rows:auto 1fr;
  height:100vh;
  max-height:100vh;
  padding:12px;
  gap:10px;
  overflow:hidden;
}

/* ── TOPBAR ── */
.topbar{
  display:flex;
  align-items:center;
  justify-content:space-between;
  background:var(--surface);
  border:1px solid var(--border);
  border-radius:var(--r);
  padding:10px 16px;
  flex-shrink:0;
  gap:12px;
}
.logo{display:flex;align-items:center;gap:10px}
.logo-icon{
  width:34px;height:34px;
  background:var(--accent);
  border-radius:8px;
  display:flex;align-items:center;justify-content:center;
  color:#fff;font-size:17px;flex-shrink:0;
}
.logo-name{font-size:15px;font-weight:600;color:var(--text)}
.logo-sub{font-size:11px;color:var(--text3);font-family:var(--mono);margin-top:1px}
.topbar-right{display:flex;align-items:center;gap:12px}
.key-status{display:flex;align-items:center;gap:7px}
.status-dot{
  width:8px;height:8px;border-radius:50%;
  background:<%= hasKeys ? "var(--ok)" : "var(--text3)" %>;
  box-shadow:<%= hasKeys ? "0 0 0 3px var(--ok-l)" : "none" %>;
}
.status-label{
  font-size:12px;font-family:var(--mono);
  color:<%= hasKeys ? "var(--ok)" : "var(--text3)" %>;
}

/* ── ALERT TOAST ── */
.toast{
  display:none;
  align-items:center;
  gap:7px;
  padding:7px 12px;
  border-radius:var(--rs);
  font-size:12.5px;
}
.toast-ok {background:var(--ok-l);border:1px solid var(--ok-b);color:var(--ok)}
.toast-err{background:var(--err-l);border:1px solid var(--err-b);color:var(--err)}

/* ── PAGE ALERTS ── */
.page-alert{
  display:flex;align-items:flex-start;gap:8px;
  padding:9px 12px;border-radius:var(--rs);
  font-size:12.5px;line-height:1.5;
  flex-shrink:0;
}
.page-alert.ok {background:var(--ok-l);border:1px solid var(--ok-b);color:var(--ok)}
.page-alert.err{background:var(--err-l);border:1px solid var(--err-b);color:var(--err)}

/* ── 3-COLUMN GRID ── */
.cols{
  display:grid;
  grid-template-columns:1fr 1fr 1fr;
  gap:10px;
  min-height:0;
  overflow:hidden;
}

/* ── COLUMN ── */
.col{
  background:var(--surface);
  border:1px solid var(--border);
  border-radius:var(--r);
  display:flex;flex-direction:column;
  overflow:hidden;min-height:0;
}
.col-head{
  padding:10px 14px;
  background:var(--surface2);
  border-bottom:1px solid var(--border);
  display:flex;align-items:center;justify-content:space-between;
  flex-shrink:0;gap:8px;
}
.col-head-l{display:flex;align-items:center;gap:8px}
.step-num{
  width:22px;height:22px;border-radius:50%;
  background:var(--accent);color:#fff;
  font-size:11.5px;font-weight:600;
  display:flex;align-items:center;justify-content:center;
  font-family:var(--mono);flex-shrink:0;
}
.col-title{font-size:13.5px;font-weight:600;color:var(--text)}
.col-body{
  padding:12px;overflow-y:auto;
  flex:1;display:flex;flex-direction:column;gap:10px;
}

/* ── SECTION CARD ── */
.card{
  background:var(--surface2);
  border:1px solid var(--border);
  border-radius:var(--rs);
  overflow:hidden;
}
.card-head{
  padding:8px 12px;
  background:var(--surface);
  border-bottom:1px solid var(--border);
  font-size:12px;font-weight:600;color:var(--text2);
  display:flex;align-items:center;justify-content:space-between;gap:8px;
}
.card-body{
  padding:10px 12px;
  display:flex;flex-direction:column;gap:9px;
}

/* ── FORM ── */
.lbl{
  display:block;font-size:11px;font-weight:600;
  color:var(--text2);text-transform:uppercase;
  letter-spacing:.4px;margin-bottom:4px;
}
input[type=text],textarea{
  width:100%;background:var(--surface);
  border:1px solid var(--border);border-radius:var(--rs);
  color:var(--text);font-family:var(--mono);font-size:11.5px;
  padding:7px 10px;outline:none;transition:border-color .15s;resize:none;
}
input:focus,textarea:focus{border-color:var(--accent);box-shadow:0 0 0 3px var(--accent-l)}
textarea{min-height:62px;max-height:80px}

/* ── FILE INPUT ── */
.file-wrap{
  border:1.5px dashed var(--border2);border-radius:var(--rs);
  padding:9px 12px;display:flex;align-items:center;gap:8px;
  cursor:pointer;transition:border-color .15s;background:var(--surface);
}
.file-wrap:hover{border-color:var(--accent)}
.file-wrap input{display:none}
.file-wrap-text{font-size:12px;color:var(--text2)}
.file-wrap-text b{color:var(--accent);font-weight:500}
.file-chosen{font-size:11px;color:var(--ok);font-family:var(--mono)}

/* ── DIVIDER ── */
.or{
  display:flex;align-items:center;gap:8px;
  color:var(--text3);font-size:11.5px;
}
.or::before,.or::after{content:'';flex:1;height:1px;background:var(--border)}

/* ── BUTTONS ── */
.btn{
  display:inline-flex;align-items:center;justify-content:center;
  gap:6px;border:none;border-radius:var(--rs);
  font-family:var(--sans);font-size:12.5px;font-weight:500;
  padding:8px 14px;cursor:pointer;transition:all .15s;
  text-decoration:none;white-space:nowrap;
}
.btn-primary{background:var(--accent);color:#fff}
.btn-primary:hover{background:var(--accent-h)}
.btn-secondary{background:var(--surface);color:var(--text);border:1px solid var(--border2)}
.btn-secondary:hover{border-color:var(--accent);color:var(--accent)}
.btn-danger{background:var(--err-l);color:var(--err);border:1px solid var(--err-b)}
.btn-danger:hover{background:#fee2e2}
.btn-ghost{
  background:transparent;color:var(--text2);border:none;
  padding:4px 8px;font-size:11.5px;cursor:pointer;
  border-radius:var(--rs);
}
.btn-ghost:hover{background:var(--border);color:var(--text)}
.btn-xs{padding:5px 10px;font-size:12px}
.btn-row{display:flex;align-items:center;gap:8px;flex-wrap:wrap}
.hint{font-size:11.5px;color:var(--text3);line-height:1.5}

/* ── KEY BOXES ── */
.key-grid{display:grid;grid-template-columns:1fr 1fr;gap:8px}
.kbox{border-radius:var(--rs);padding:8px 10px}
.kbox-priv{background:var(--warn-l);border:1px solid var(--warn-b)}
.kbox-pub {background:var(--info-l);border:1px solid var(--info-b)}
.kbox-lbl{
  font-size:10.5px;font-weight:600;
  text-transform:uppercase;letter-spacing:.3px;margin-bottom:5px;
}
.kbox-priv .kbox-lbl{color:var(--warn)}
.kbox-pub  .kbox-lbl{color:var(--info)}
.kbox-val{font-family:var(--mono);font-size:10.5px;color:var(--text);word-break:break-all;line-height:1.7}

/* key inline input */
.kbox-priv input[type=text]{
  background:transparent;border:none;
  border-bottom:1px solid var(--warn-b);
  border-radius:0;padding:3px 0;
  font-size:11px;color:var(--text);
  box-shadow:none;
}
.kbox-priv input:focus{border-bottom-color:var(--warn);box-shadow:none}

/* ── SIGNATURE OUTPUT ── */
.sig-out{
  border:1px solid var(--ok-b);border-radius:var(--rs);
  overflow:hidden;background:var(--ok-l);
}
.sig-out-head{
  padding:8px 12px;background:#dcfce7;
  border-bottom:1px solid var(--ok-b);
  font-size:12px;font-weight:600;color:var(--ok);
  display:flex;align-items:center;justify-content:space-between;
}
.sig-field{padding:8px 12px;border-bottom:1px solid var(--ok-b)}
.sig-field:last-child{border-bottom:none}
.sig-field-lbl{
  font-size:10.5px;font-weight:600;color:var(--text2);
  text-transform:uppercase;letter-spacing:.3px;
  margin-bottom:4px;
  display:flex;align-items:center;justify-content:space-between;
}
.sig-field-val{font-family:var(--mono);font-size:11px;color:var(--text);word-break:break-all;line-height:1.7}

/* ── COPY TO VERIFY ── */
.c2v{
  background:var(--accent-l);border:1px solid #c7d2fc;
  border-radius:var(--rs);padding:8px 11px;
  display:flex;align-items:center;justify-content:space-between;gap:8px;flex-wrap:wrap;
}
.c2v span{font-size:12px;color:var(--text2)}

/* ── VERIFY RESULT ── */
.vr{border-radius:var(--rs);padding:12px 14px;display:flex;align-items:center;gap:12px}
.vr-ok {background:var(--ok-l);border:1px solid var(--ok-b)}
.vr-err{background:var(--err-l);border:1px solid var(--err-b)}
.vr-icon{
  width:42px;height:42px;border-radius:50%;
  display:flex;align-items:center;justify-content:center;
  font-size:20px;flex-shrink:0;
}
.vr-ok  .vr-icon{background:#dcfce7}
.vr-err .vr-icon{background:#fee2e2}
.vr-title{font-size:13.5px;font-weight:600;margin-bottom:2px}
.vr-ok  .vr-title{color:var(--ok)}
.vr-err .vr-title{color:var(--err)}
.vr-desc{font-size:11.5px;color:var(--text2)}

/* ── COPY FEEDBACK ── */
.cf{font-size:10.5px;color:var(--ok);opacity:0;transition:opacity .3s;margin-left:4px}
.cf.show{opacity:1}

/* ── SCROLLBAR ── */
.col-body::-webkit-scrollbar{width:4px}
.col-body::-webkit-scrollbar-track{background:transparent}
.col-body::-webkit-scrollbar-thumb{background:var(--border2);border-radius:4px}

/* ── RESPONSIVE ── */
@media(max-width:768px){
  .cols{grid-template-columns:1fr}
  .app{height:auto;max-height:none;overflow:auto}
  .key-grid{grid-template-columns:1fr}
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
      <!-- Page-level alerts from server -->
      <% if (request.getAttribute("error") != null) { %>
      <div class="page-alert err">⚠ ${error}</div>
      <% } %>
      <% if (request.getAttribute("successMsg") != null) { %>
      <div class="page-alert ok">✓ ${successMsg}</div>
      <% } %>
      <!-- Key status -->
      <div class="key-status">
        <div class="status-dot"></div>
        <span class="status-label"><%= hasKeys ? "Khóa đã sẵn sàng" : "Chưa có khóa" %></span>
      </div>
      <!-- JS toast -->
      <div class="toast" id="toast"></div>
    </div>
  </header>

  <!-- 3 COLUMNS -->
  <div class="cols">

    <!-- ════════════════════════════ COL 1: KHỞI TẠO KHÓA ════════════════════════════ -->
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

        <!-- Sinh tự động -->
        <div class="card">
          <div class="card-head">🎲 Sinh khóa tự động</div>
          <div class="card-body">
            <p class="hint">Tự động tạo nhóm Schnorr (p 512-bit, q 160-bit) cùng cặp khóa ngẫu nhiên an toàn.</p>
            <form action="schnorr?action=generateKeys" method="post">
              <button type="submit" class="btn btn-primary">⚡ Tự động sinh bộ khóa</button>
            </form>
          </div>
        </div>

        <!-- Tham số thủ công -->
        <div class="card">
          <div class="card-head">
            ⚙ Tham số &amp; khóa (HEX)
            <% if (hasKeys) { %>
            <button class="btn-ghost btn-xs" onclick="copyAllKeys()">⎘ Copy tất cả<span class="cf" id="cfAll"></span></button>
            <% } %>
          </div>
          <div class="card-body">
            <form action="schnorr?action=setKeys" method="post">
              <div style="display:flex;flex-direction:column;gap:9px">
                <div>
                  <label class="lbl">Modulus p (số nguyên tố lớn)</label>
                  <input type="text" name="p" value="${pHex}" placeholder="Nhập giá trị HEX của p...">
                </div>
                <div>
                  <label class="lbl">Bậc q (số nguyên tố 160-bit)</label>
                  <input type="text" name="q" value="${qHex}" placeholder="Nhập giá trị HEX của q...">
                </div>
                <div>
                  <label class="lbl">Bộ sinh g &nbsp;(g<sup>q</sup> ≡ 1 mod p)</label>
                  <input type="text" name="g" value="${gHex}" placeholder="Nhập giá trị HEX của g...">
                </div>

                <div class="key-grid">
                  <div class="kbox kbox-priv">
                    <div class="kbox-lbl">🔑 Khóa bí mật (x)</div>
                    <input type="text" name="privateKey" value="${privateKey}" placeholder="Nhập x (HEX)...">
                  </div>
                  <div class="kbox kbox-pub">
                    <div class="kbox-lbl">🌐 Khóa công khai (y)</div>
                    <div class="kbox-val">${not empty publicKey ? publicKey : '— chưa có —'}</div>
                  </div>
                </div>

                <div class="btn-row">
                  <button type="submit" class="btn btn-secondary">✓ Áp dụng thủ công</button>
                  <span class="hint">Tham số sẽ được kiểm tra trước khi lưu.</span>
                </div>
              </div>
            </form>
          </div>
        </div>

      </div>
    </div>
    <!-- end col 1 -->


    <!-- ════════════════════════════ COL 2: KÝ SỐ ════════════════════════════ -->
    <div class="col">
      <div class="col-head">
        <div class="col-head-l">
          <div class="step-num">2</div>
          <span class="col-title">Ký văn bản</span>
        </div>
      </div>
      <div class="col-body">

        <% if (!hasKeys) { %>
        <div class="page-alert err" style="font-size:12.5px">
          ℹ Chưa có khóa. Vui lòng hoàn thành Bước 1 trước.
        </div>
        <% } %>

        <!-- Khóa đang dùng -->
        <% if (hasKeys) { %>
        <div class="card">
          <div class="card-head">🔑 Khóa đang dùng</div>
          <div class="card-body">
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

        <!-- Form ký -->
        <div class="card">
          <div class="card-head">✍ Tạo chữ ký</div>
          <div class="card-body">
            <form action="schnorr?action=sign" method="post" enctype="multipart/form-data">
              <div style="display:flex;flex-direction:column;gap:9px">
                <div>
                  <label class="lbl">Cách 1 — Tải file .txt</label>
                  <label class="file-wrap" for="signFileTxt">
                    <span style="font-size:18px">📄</span>
                    <div class="file-wrap-text">
                      <b>Chọn file</b> hoặc kéo thả vào đây
                      <div style="font-size:10.5px;color:var(--text3);margin-top:2px">Chỉ .txt · Tối đa 10 MB</div>
                    </div>
                    <input type="file" id="signFileTxt" name="fileTxt" accept=".txt"
                           onchange="updateFileName(this,'signFileChosen')">
                  </label>
                  <div class="file-chosen" id="signFileChosen"></div>
                </div>

                <div class="or">hoặc</div>

                <div>
                  <label class="lbl">Cách 2 — Nhập văn bản trực tiếp</label>
                  <textarea name="message" placeholder="Nhập nội dung cần ký vào đây...">${signedMessage}</textarea>
                </div>

                <button type="submit" class="btn btn-primary" <%= !hasKeys ? "disabled style='opacity:.5;cursor:not-allowed'" : "" %>>
                  🖊 Thực hiện ký số
                </button>
              </div>
            </form>
          </div>
        </div>

        <!-- Kết quả chữ ký -->
        <% if (request.getAttribute("sigE") != null) { %>
        <div class="sig-out">
          <div class="sig-out-head">
            ✓ Chữ ký đã tạo
            <button class="btn-ghost btn-xs" onclick="copySig()" style="color:var(--ok);cursor:pointer;background:transparent;border:none;font-size:11.5px">
              ⎘ Copy (e, s)<span class="cf" id="cfSig"></span>
            </button>
          </div>
          <div class="sig-field">
            <div class="sig-field-lbl">
              Thành phần băm e
              <button class="btn-ghost" onclick="copyText('${sigE}','cfE')" style="font-size:11px;cursor:pointer;background:transparent;border:none">
                ⎘<span class="cf" id="cfE"></span>
              </button>
            </div>
            <div class="sig-field-val" id="outSigE">${sigE}</div>
          </div>
          <div class="sig-field">
            <div class="sig-field-lbl">
              Thành phần chứng thực s
              <button class="btn-ghost" onclick="copyText('${sigS}','cfS')" style="font-size:11px;cursor:pointer;background:transparent;border:none">
                ⎘<span class="cf" id="cfS"></span>
              </button>
            </div>
            <div class="sig-field-val" id="outSigS">${sigS}</div>
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
    </div>
    <!-- end col 2 -->


    <!-- ════════════════════════════ COL 3: XÁC MINH ════════════════════════════ -->
    <div class="col">
      <div class="col-head">
        <div class="col-head-l">
          <div class="step-num">3</div>
          <span class="col-title">Xác minh chữ ký</span>
        </div>
      </div>
      <div class="col-body">

        <% if (!hasKeys) { %>
        <div class="page-alert err" style="font-size:12.5px">
          ℹ Chưa có khóa công khai. Vui lòng hoàn thành Bước 1 trước.
        </div>
        <% } %>

        <div class="card">
          <div class="card-head">🔍 Nhập dữ liệu xác minh</div>
          <div class="card-body">
            <form action="schnorr?action=verify" method="post" enctype="multipart/form-data">
              <div style="display:flex;flex-direction:column;gap:9px">
                <div>
                  <label class="lbl">Cách 1 — Tải file gốc .txt</label>
                  <label class="file-wrap" for="verifyFileTxt">
                    <span style="font-size:18px">📄</span>
                    <div class="file-wrap-text">
                      <b>Chọn file</b> hoặc kéo thả vào đây
                      <div style="font-size:10.5px;color:var(--text3);margin-top:2px">Chỉ .txt · Tối đa 10 MB</div>
                    </div>
                    <input type="file" id="verifyFileTxt" name="verifyFileTxt" accept=".txt"
                           onchange="updateFileName(this,'verifyFileChosen')">
                  </label>
                  <div class="file-chosen" id="verifyFileChosen"></div>
                </div>

                <div class="or">hoặc</div>

                <div>
                  <label class="lbl">Cách 2 — Dán nội dung văn bản</label>
                  <textarea name="verifyMessage" id="verifyMsgArea"
                            placeholder="Dán nội dung văn bản gốc...">${verifyMessage}</textarea>
                </div>

                <div class="key-grid">
                  <div>
                    <label class="lbl">Chữ ký e (HEX)</label>
                    <input type="text" name="sigE" id="verifyE"
                           value="${verifyE}" placeholder="Dán giá trị e...">
                  </div>
                  <div>
                    <label class="lbl">Chữ ký s (HEX)</label>
                    <input type="text" name="sigS" id="verifyS"
                           value="${verifyS}" placeholder="Dán giá trị s...">
                  </div>
                </div>

                <button type="submit" class="btn btn-primary" <%= !hasKeys ? "disabled style='opacity:.5;cursor:not-allowed'" : "" %>>
                  🔍 Bắt đầu xác minh
                </button>
              </div>
            </form>
          </div>
        </div>

        <!-- Kết quả xác minh -->
        <% if (request.getAttribute("verifyResult") != null) {
               boolean isValid = (Boolean) request.getAttribute("verifyResult"); %>
        <div class="vr <%= isValid ? "vr-ok" : "vr-err" %>">
          <div class="vr-icon"><%= isValid ? "✓" : "✕" %></div>
          <div>
            <div class="vr-title"><%= isValid ? "CHỮ KÝ HỢP LỆ" : "CHỮ KÝ KHÔNG HỢP LỆ" %></div>
            <div class="vr-desc">
              <%= isValid
                  ? "Nội dung toàn vẹn, chữ ký khớp với khóa công khai."
                  : "Cảnh báo: nội dung bị thay đổi hoặc chữ ký / khóa không tương ứng." %>
            </div>
          </div>
        </div>
        <% } %>

      </div>
    </div>
    <!-- end col 3 -->

  </div>
</div>

<script>
/* ── File name ── */
function updateFileName(input, targetId) {
  const el = document.getElementById(targetId);
  el.textContent = input.files[0] ? '📎 ' + input.files[0].name : '';
}

/* ── Copy helpers ── */
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
  const text = 'p: '+p+'\nq: '+q+'\ng: '+g+'\nx (private): '+x+'\ny (public): '+y;
  navigator.clipboard.writeText(text).then(() => {
    const el = document.getElementById('cfAll');
    if (!el) return;
    el.textContent = ' Đã copy!';
    el.classList.add('show');
    setTimeout(() => el.classList.remove('show'), 1800);
  });
}

/* ── Chuyển sang tab xác minh ── */
function goVerify(e, s, msg) {
  const eEl = document.getElementById('verifyE');
  const sEl = document.getElementById('verifyS');
  const mEl = document.getElementById('verifyMsgArea');
  if (eEl) eEl.value = e;
  if (sEl) sEl.value = s;
  if (mEl && msg && msg.trim()) mEl.value = msg;

  // Cuộn xuống cột 3
  const col3 = document.querySelectorAll('.col')[2];
  if (col3) col3.scrollIntoView({ behavior: 'smooth', block: 'start' });
  if (eEl) eEl.focus();
}
</script>
</body>
</html>
