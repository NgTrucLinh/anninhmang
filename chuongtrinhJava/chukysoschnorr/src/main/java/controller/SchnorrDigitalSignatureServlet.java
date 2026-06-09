package controller;

import model.SchnorrDigitalSignatureModel;
import model.SchnorrDigitalSignatureModel.ManualKeyResult;
import model.SchnorrDigitalSignatureModel.VerifyResult;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import org.apache.poi.xssf.usermodel.XSSFWorkbook;          // xlsx
import org.apache.poi.hssf.usermodel.HSSFWorkbook;           // xls
import org.apache.poi.ss.usermodel.*;
import org.apache.poi.xwpf.usermodel.XWPFDocument;           // docx
//import org.apache.poi.hwpf.HWPFDocument;                     // doc
//import org.apache.poi.hwpf.extractor.WordExtractor;

import java.io.*;
import java.math.BigInteger;
import java.nio.charset.StandardCharsets;
import java.util.*;
import java.util.stream.Collectors;

@WebServlet(name = "SchnorrDigitalSignatureServlet", urlPatterns = { "/schnorr" })
@MultipartConfig(
    fileSizeThreshold = 1024 * 1024 * 2,   // 2 MB
    maxFileSize       = 1024 * 1024 * 10,  // 10 MB
    maxRequestSize    = 1024 * 1024 * 50   // 50 MB
)
public class SchnorrDigitalSignatureServlet extends HttpServlet {

    // Các phần mở rộng file được chấp nhận
    private static final Set<String> ALLOWED_EXTENSIONS =
        new HashSet<>(Arrays.asList("txt", "xlsx", "xls", "docx", "doc"));

    // ═══════════════════════════════════════════════════════
    //  ĐIỀU HƯỚNG REQUEST
    // ═══════════════════════════════════════════════════════
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.getRequestDispatcher("/index.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        HttpSession session = request.getSession();

        String action = request.getParameter("action");

        try {
            switch (action == null ? "" : action) {
                case "generateKeys" -> handleGenerateKeys(request, session);
                case "setKeys"      -> handleSetKeys(request, session);
                case "sign"         -> handleSign(request, session);
                case "verify"       -> handleVerify(request, session);
                case "reset"        -> handleReset(request, session);
                default -> {
                    request.setAttribute("error", "Hành động không hợp lệ.");
                    request.setAttribute("activeTab", "keygen");
                }
            }
        } catch (Exception ex) {
            request.setAttribute("error", "Lỗi hệ thống: " + ex.getMessage());
        }

        request.getRequestDispatcher("/index.jsp").forward(request, response);
    }

    // ═══════════════════════════════════════════════════════
    //  SINH KHÓA TỰ ĐỘNG (có chọn kích thước bit)
    // ═══════════════════════════════════════════════════════
    private void handleGenerateKeys(HttpServletRequest request, HttpSession session) {
        request.setAttribute("activeTab", "keygen");

        // Đọc kích thước bit từ form (nếu người dùng chọn)
        int pBits = parseIntParam(request.getParameter("pBits"), 512);
        int qBits = parseIntParam(request.getParameter("qBits"), 160);

        // Validate tổ hợp bit hợp lệ
        String bitError = validateBitSizes(pBits, qBits);
        if (bitError != null) {
            request.setAttribute("error", bitError);
            return;
        }

        try {
            SchnorrDigitalSignatureModel model = new SchnorrDigitalSignatureModel();
            model.generateKeys(pBits, qBits);
            session.setAttribute("schnorrModel", model);
            request.setAttribute("successMsg",
                "✅ Tạo bộ khóa ngẫu nhiên thành công! "
                + "(p = " + pBits + " bit, q = " + qBits + " bit)");
            request.setAttribute("selectedPBits", pBits);
            request.setAttribute("selectedQBits", qBits);
            pushKeysToUI(request, model);
        } catch (IllegalStateException e) {
            request.setAttribute("error",
                "⚠️ Sinh khóa thất bại: " + e.getMessage()
                + " — Thử nhấn sinh lại một lần nữa.");
        }
    }

    /** Kiểm tra tổ hợp kích thước bit hợp lệ cho Schnorr */
    private String validateBitSizes(int pBits, int qBits) {
        Set<Integer> validP = new HashSet<>(Arrays.asList(512, 1024, 2048));
        Set<Integer> validQ = new HashSet<>(Arrays.asList(160, 224, 256));
        if (!validP.contains(pBits))
            return "Kích thước p không hợp lệ. Chọn một trong: 512, 1024, 2048 bit.";
        if (!validQ.contains(qBits))
            return "Kích thước q không hợp lệ. Chọn một trong: 160, 224, 256 bit.";
        if (pBits <= qBits)
            return "Kích thước p phải lớn hơn q. Hãy chọn lại.";
        return null;
    }

    // ═══════════════════════════════════════════════════════
    //  NHẬP KHÓA THỦ CÔNG (báo lỗi từng trường cụ thể)
    // ═══════════════════════════════════════════════════════
    private void handleSetKeys(HttpServletRequest request, HttpSession session) {
        request.setAttribute("activeTab", "keygen");

        String p = trim(request.getParameter("p"));
        String q = trim(request.getParameter("q"));
        String g = trim(request.getParameter("g"));
        String x = trim(request.getParameter("privateKey"));

        // Giữ lại giá trị đã nhập để hiển thị lại form
        request.setAttribute("pHex",       p);
        request.setAttribute("qHex",       q);
        request.setAttribute("gHex",       g);
        request.setAttribute("privateKey", x);

        // Kiểm tra thiếu trường
        Map<String, String> missing = new LinkedHashMap<>();
        if (p.isEmpty()) missing.put("p", "Chưa nhập tham số p (số nguyên tố lớn).");
        if (q.isEmpty()) missing.put("q", "Chưa nhập tham số q (số nguyên tố nhỏ, chia hết p−1).");
        if (g.isEmpty()) missing.put("g", "Chưa nhập bộ phát sinh g.");
        if (x.isEmpty()) missing.put("x", "Chưa nhập khóa bí mật x.");

        if (!missing.isEmpty()) {
            request.setAttribute("fieldErrors", missing);
            request.setAttribute("error",
                "⚠️ Thiếu " + missing.size() + " trường bắt buộc. Xem chi tiết bên dưới.");
            return;
        }

        try {
            SchnorrDigitalSignatureModel model = new SchnorrDigitalSignatureModel();
            ManualKeyResult result = model.setKeysManual(p, q, g, x, null);

            if (!result.success) {
                // Gom lỗi từng trường vào Map để JSP hiển thị inline
                Map<String, String> fieldErrors = new LinkedHashMap<>();
                if (result.errorP != null) fieldErrors.put("p", result.errorP);
                if (result.errorQ != null) fieldErrors.put("q", result.errorQ);
                if (result.errorG != null) fieldErrors.put("g", result.errorG);
                if (result.errorX != null) fieldErrors.put("x", result.errorX);
                request.setAttribute("fieldErrors", fieldErrors);
                request.setAttribute("error",
                    "⚠️ Có " + fieldErrors.size() + " tham số không hợp lệ. Xem chi tiết bên dưới từng ô.");
                return;
            }

            session.setAttribute("schnorrModel", model);
            request.setAttribute("successMsg",
                "✅ Cấu hình khóa thủ công thành công!");
            pushKeysToUI(request, model);

        } catch (Exception e) {
            request.setAttribute("error", "Lỗi không xác định: " + e.getMessage());
        }
    }

    // ═══════════════════════════════════════════════════════
    //  KÝ SỐ (hỗ trợ TXT, Excel, Word)
    // ═══════════════════════════════════════════════════════
    private void handleSign(HttpServletRequest request, HttpSession session) throws Exception {
        request.setAttribute("activeTab", "sign");

        SchnorrDigitalSignatureModel model = getModel(session);
        if (model != null) pushKeysToUI(request, model);

        if (model == null || model.getPrivateKey() == null) {
            request.setAttribute("error",
                "⚠️ Chưa có thông tin khóa. Vui lòng tạo hoặc nhập khóa trước (tab Tạo Khóa).");
            return;
        }

        String msg = readMessageFromRequest(request, "fileTxt", "message");
        if (msg == null) return; // lỗi đã set vào request

        try {
            BigInteger[] sig = model.sign(msg);
            request.setAttribute("sigE",         sig[0].toString(16).toUpperCase());
            request.setAttribute("sigS",         sig[1].toString(16).toUpperCase());
            request.setAttribute("signedMessage", msg);
            request.setAttribute("successMsg",   "✅ Ký số thành công!");
        } catch (Exception e) {
            request.setAttribute("error",        "Lỗi trong quá trình ký: " + e.getMessage());
            request.setAttribute("signedMessage", msg);
        }
    }

    // ═══════════════════════════════════════════════════════
    //  XÁC MINH CHỮ KÝ (phân biệt lỗi nội dung / chữ ký)
    // ═══════════════════════════════════════════════════════
    private void handleVerify(HttpServletRequest request, HttpSession session) throws Exception {
        request.setAttribute("activeTab", "verify");

        SchnorrDigitalSignatureModel model = getModel(session);
        if (model != null) pushKeysToUI(request, model);

        if (model == null || model.getPublicKey() == null) {
            request.setAttribute("error",
                "⚠️ Chưa thiết lập khóa công khai. Vui lòng tạo hoặc nhập khóa trước.");
            return;
        }

        String msg = readMessageFromRequest(request, "verifyFileTxt", "verifyMessage");
        String e   = trim(request.getParameter("sigE"));
        String s   = trim(request.getParameter("sigS"));

        // Trả lại giá trị để hiển thị lại form
        request.setAttribute("verifyMessage",
            msg != null ? msg : trim(request.getParameter("verifyMessage")));
        request.setAttribute("verifyE", e);
        request.setAttribute("verifyS", s);

        if (msg == null) return;

        if (e.isEmpty() && s.isEmpty()) {
            request.setAttribute("error", "⚠️ Chưa nhập cặp chữ ký e và s.");
            return;
        }
        if (e.isEmpty()) {
            request.setAttribute("error", "⚠️ Chưa nhập giá trị e của chữ ký.");
            return;
        }
        if (s.isEmpty()) {
            request.setAttribute("error", "⚠️ Chưa nhập giá trị s của chữ ký.");
            return;
        }

        try {
            VerifyResult vr = model.verifyDetailed(msg, e, s);
            request.setAttribute("verifyResult",       vr.isValid());
            request.setAttribute("verifyStatus",       vr.status.name());
            request.setAttribute("verifyDetail",       vr.detail);

            if (vr.isValid()) {
                request.setAttribute("successMsg",
                    "✅ Xác minh THÀNH CÔNG — Tài liệu toàn vẹn, chữ ký hợp lệ.");
            } else {
                // Thông báo lỗi chi tiết theo từng trường hợp
                String errorMsg = buildVerifyErrorMessage(vr);
                request.setAttribute("error", errorMsg);
            }
        } catch (Exception ex) {
            request.setAttribute("error",
                "Lỗi trong quá trình xác minh: " + ex.getMessage());
        }
    }

    /** Tạo thông báo lỗi xác minh dễ hiểu theo từng loại */
    private String buildVerifyErrorMessage(VerifyResult vr) {
        return switch (vr.status) {
            case INVALID_SIGNATURE_E ->
                "❌ Xác minh THẤT BẠI — Chữ ký e không hợp lệ.\n"
                + vr.detail;
            case INVALID_SIGNATURE_S ->
                "❌ Xác minh THẤT BẠI — Chữ ký s không hợp lệ.\n"
                + vr.detail;
            case INVALID_SIGNATURE_BOTH ->
                "❌ Xác minh THẤT BẠI — Cả hai giá trị e và s đều không hợp lệ.\n"
                + vr.detail;
            case TAMPERED_MESSAGE ->
                "❌ Xác minh THẤT BẠI — Nội dung văn bản hoặc chữ ký bị thay đổi.\n"
                + vr.detail;
            case INVALID_FORMAT ->
                "❌ Định dạng chữ ký sai — " + vr.detail
                + " Chữ ký phải là chuỗi HEX (0-9, A-F).";
            default ->
                "❌ Xác minh THẤT BẠI — " + vr.detail;
        };
    }

    // ═══════════════════════════════════════════════════════
    //  RESET
    // ═══════════════════════════════════════════════════════
    private void handleReset(HttpServletRequest request, HttpSession session) {
        session.removeAttribute("schnorrModel");
        request.setAttribute("activeTab", "keygen");
        request.setAttribute("successMsg",
            "🔄 Đã đặt lại toàn bộ hệ thống. Vui lòng tạo bộ khóa mới.");
    }

    // ═══════════════════════════════════════════════════════
    //  ĐỌC NỘI DUNG TỪ FILE (TXT / EXCEL / WORD) HOẶC TEXTAREA
    // ═══════════════════════════════════════════════════════
    private String readMessageFromRequest(HttpServletRequest request,
                                          String filePart, String textParam)
            throws Exception {
        Part part = request.getPart(filePart);
        String msg;

        if (part != null && part.getSize() > 0) {
            String fileName = part.getSubmittedFileName();
            if (fileName == null || fileName.isBlank()) {
                request.setAttribute("error",
                    "Không xác định được tên file. Vui lòng chọn lại.");
                return null;
            }

            String ext = getExtension(fileName).toLowerCase();
            if (!ALLOWED_EXTENSIONS.contains(ext)) {
                request.setAttribute("error",
                    "⚠️ Định dạng file \"." + ext + "\" không được hỗ trợ. "
                    + "Chỉ chấp nhận: .txt, .xlsx, .xls, .docx, .doc");
                return null;
            }

            msg = extractTextFromPart(part, ext, request);
            if (msg == null) return null; // lỗi đã set
        } else {
            msg = request.getParameter(textParam);
        }

        if (msg == null || msg.isBlank()) {
            request.setAttribute("error",
                "⚠️ Vui lòng nhập nội dung văn bản hoặc tải lên file "
                + "(hỗ trợ: .txt, .xlsx, .xls, .docx, .doc).");
            return null;
        }
        return msg;
    }

    /** Trích xuất nội dung text từ file theo định dạng */
    private String extractTextFromPart(Part part, String ext, HttpServletRequest request)
            throws IOException {
        try (InputStream is = part.getInputStream()) {
            return switch (ext) {
                case "txt"  -> readText(is);
                case "xlsx" -> readXlsx(is);
                case "xls"  -> readXls(is);
                case "docx" -> readDocx(is);
          //   case "doc"  -> readDoc(is);
                default     -> null;
            };
        } catch (Exception e) {
            request.setAttribute("error",
                "Không thể đọc file: " + e.getMessage()
                + ". Hãy kiểm tra file có đúng định dạng không.");
            return null;
        }
    }

    // ── Đọc file TXT ──
    private String readText(InputStream is) throws IOException {
        try (BufferedReader reader = new BufferedReader(
                new InputStreamReader(is, StandardCharsets.UTF_8))) {
            return reader.lines().collect(Collectors.joining("\n"));
        }
    }

    // ── Đọc file XLSX (Excel mới) ──
    private String readXlsx(InputStream is) throws Exception {
        StringBuilder sb = new StringBuilder();
        try (XSSFWorkbook wb = new XSSFWorkbook(is)) {
            for (int si = 0; si < wb.getNumberOfSheets(); si++) {
                Sheet sheet = wb.getSheetAt(si);
                if (si > 0) sb.append("\n--- Sheet: ").append(sheet.getSheetName()).append(" ---\n");
                for (Row row : sheet) {
                    List<String> cells = new ArrayList<>();
                    for (Cell cell : row) {
                        cells.add(cellToString(cell));
                    }
                    sb.append(String.join("\t", cells)).append("\n");
                }
            }
        }
        return sb.toString().trim();
    }

    // ── Đọc file XLS (Excel cũ) ──
    private String readXls(InputStream is) throws Exception {
        StringBuilder sb = new StringBuilder();
        try (HSSFWorkbook wb = new HSSFWorkbook(is)) {
            for (int si = 0; si < wb.getNumberOfSheets(); si++) {
                Sheet sheet = wb.getSheetAt(si);
                if (si > 0) sb.append("\n--- Sheet: ").append(sheet.getSheetName()).append(" ---\n");
                for (Row row : sheet) {
                    List<String> cells = new ArrayList<>();
                    for (Cell cell : row) {
                        cells.add(cellToString(cell));
                    }
                    sb.append(String.join("\t", cells)).append("\n");
                }
            }
        }
        return sb.toString().trim();
    }

    /** Chuyển ô Excel sang chuỗi */
    private String cellToString(Cell cell) {
        if (cell == null) return "";
        DataFormatter formatter = new DataFormatter();
        return formatter.formatCellValue(cell).trim();
    }

    // ── Đọc file DOCX (Word mới) ──
    private String readDocx(InputStream is) throws Exception {
        StringBuilder sb = new StringBuilder();
        try (XWPFDocument doc = new XWPFDocument(is)) {
            doc.getParagraphs().forEach(p -> {
                String text = p.getText();
                if (!text.isBlank()) sb.append(text).append("\n");
            });
            // Đọc cả bảng trong Word
            doc.getTables().forEach(table ->
                table.getRows().forEach(row -> {
                    List<String> cells = new ArrayList<>();
                    row.getTableCells().forEach(cell -> cells.add(cell.getText().trim()));
                    sb.append(String.join("\t", cells)).append("\n");
                })
            );
        }
        return sb.toString().trim();
    }

    // ── Đọc file DOC (Word cũ) ──
   //private String readDoc(InputStream is) throws Exception {
    //    try (HWPFDocument doc = new HWPFDocument(is);
     //        WordExtractor extractor = new WordExtractor(doc)) {
      //      return extractor.getText().trim();
      //  }
   // }

    // ═══════════════════════════════════════════════════════
    //  TIỆN ÍCH
    // ═══════════════════════════════════════════════════════
    private void pushKeysToUI(HttpServletRequest req, SchnorrDigitalSignatureModel m) {
        req.setAttribute("pHex",            m.getPHex());
        req.setAttribute("qHex",            m.getQHex());
        req.setAttribute("gHex",            m.getGHex());
        req.setAttribute("privateKey",      m.getPrivateKeyHex());
        req.setAttribute("publicKey",       m.getPublicKeyHex());
        req.setAttribute("selectedPBits",   m.getPBits());
        req.setAttribute("selectedQBits",   m.getQBits());
    }

    private SchnorrDigitalSignatureModel getModel(HttpSession session) {
        return (SchnorrDigitalSignatureModel) session.getAttribute("schnorrModel");
    }

    private String trim(String s) {
        return s != null ? s.trim() : "";
    }

    private String getExtension(String fileName) {
        int dot = fileName.lastIndexOf('.');
        return (dot >= 0 && dot < fileName.length() - 1)
            ? fileName.substring(dot + 1)
            : "";
    }

    private int parseIntParam(String val, int defaultVal) {
        try {
            return (val != null && !val.isBlank()) ? Integer.parseInt(val.trim()) : defaultVal;
        } catch (NumberFormatException e) {
            return defaultVal;
        }
    }
}