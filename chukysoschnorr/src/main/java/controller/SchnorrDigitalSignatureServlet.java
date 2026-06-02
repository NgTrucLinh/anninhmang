package controller;

import model.SchnorrDigitalSignatureModel;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.math.BigInteger;
import java.nio.charset.StandardCharsets;
import java.util.stream.Collectors;

@WebServlet(name = "SchnorrDigitalSignatureServlet", urlPatterns = { "/schnorr" })
@MultipartConfig(
    fileSizeThreshold = 1024 * 1024 * 2,   // 2 MB
    maxFileSize       = 1024 * 1024 * 10,  // 10 MB
    maxRequestSize    = 1024 * 1024 * 50   // 50 MB
)
public class SchnorrDigitalSignatureServlet extends HttpServlet {

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

        // Đọc action từ query string (tương thích multipart form)
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

    // ─────────────────────────────────────────────
    //  SINH KHÓA TỰ ĐỘNG
    // ─────────────────────────────────────────────
    private void handleGenerateKeys(HttpServletRequest request, HttpSession session) {
        request.setAttribute("activeTab", "keygen");
        try {
            SchnorrDigitalSignatureModel model = new SchnorrDigitalSignatureModel();
            model.generateKeys();
            session.setAttribute("schnorrModel", model);
            request.setAttribute("successMsg", "Tạo bộ khóa ngẫu nhiên thành công!");
            pushKeysToUI(request, model);
        } catch (IllegalStateException e) {
            request.setAttribute("error", "Sinh khóa thất bại: " + e.getMessage());
        }
    }

    // ─────────────────────────────────────────────
    //  NHẬP KHÓA THỦ CÔNG
    // ─────────────────────────────────────────────
    private void handleSetKeys(HttpServletRequest request, HttpSession session) {
        request.setAttribute("activeTab", "keygen");

        String p = trim(request.getParameter("p"));
        String q = trim(request.getParameter("q"));
        String g = trim(request.getParameter("g"));
        String x = trim(request.getParameter("privateKey"));

        if (p.isEmpty() || q.isEmpty() || g.isEmpty() || x.isEmpty()) {
            request.setAttribute("error", "Vui lòng nhập đầy đủ các tham số p, q, g và khóa bí mật x.");
            // Giữ lại giá trị đã nhập
            request.setAttribute("pHex", p);
            request.setAttribute("qHex", q);
            request.setAttribute("gHex", g);
            request.setAttribute("privateKey", x);
            return;
        }

        try {
            SchnorrDigitalSignatureModel model = new SchnorrDigitalSignatureModel();
            // Tính y = g^(-x) mod p; setKeysManual sẽ tự tính lại nếu yHex trống
            BigInteger pVal = new BigInteger(p, 16);
            BigInteger qVal = new BigInteger(q, 16);
            BigInteger gVal = new BigInteger(g, 16);
            BigInteger xVal = new BigInteger(x, 16);
            BigInteger yVal = gVal.modPow(xVal.negate().mod(qVal), pVal);

            model.setKeysManual(p, q, g, x, yVal.toString(16));
            session.setAttribute("schnorrModel", model);
            request.setAttribute("successMsg", "Cấu hình khóa thủ công thành công!");
            pushKeysToUI(request, model);
        } catch (NumberFormatException e) {
            request.setAttribute("error", "Tham số phải là chuỗi HEX hợp lệ (0-9, A-F).");
            preserveManualInput(request, p, q, g, x);
        } catch (IllegalArgumentException e) {
            request.setAttribute("error", "Tham số không hợp lệ: " + e.getMessage());
            preserveManualInput(request, p, q, g, x);
        }
    }

    // ─────────────────────────────────────────────
    //  KÝ SỐ
    // ─────────────────────────────────────────────
    private void handleSign(HttpServletRequest request, HttpSession session) throws Exception {
        request.setAttribute("activeTab", "sign");
        SchnorrDigitalSignatureModel model = getModel(session);
        if (model != null) pushKeysToUI(request, model);

        if (model == null || model.getPrivateKey() == null) {
            request.setAttribute("error", "Chưa có thông tin khóa. Vui lòng tạo hoặc nhập khóa trước.");
            return;
        }

        String msg = readMessage(request, "fileTxt", "message", "txt");
        if (msg == null) return; // lỗi đã set vào request

        try {
            BigInteger[] sig = model.sign(msg);
            request.setAttribute("sigE", sig[0].toString(16).toUpperCase());
            request.setAttribute("sigS", sig[1].toString(16).toUpperCase());
            request.setAttribute("signedMessage", msg);
            request.setAttribute("successMsg", "Ký số thành công!");
        } catch (Exception e) {
            request.setAttribute("error", "Lỗi trong quá trình ký: " + e.getMessage());
            request.setAttribute("signedMessage", msg);
        }
    }

    // ─────────────────────────────────────────────
    //  XÁC MINH CHỮ KÝ
    // ─────────────────────────────────────────────
    private void handleVerify(HttpServletRequest request, HttpSession session) throws Exception {
        request.setAttribute("activeTab", "verify");
        SchnorrDigitalSignatureModel model = getModel(session);
        if (model != null) pushKeysToUI(request, model);

        if (model == null || model.getPublicKey() == null) {
            request.setAttribute("error", "Chưa thiết lập khóa công khai. Vui lòng tạo hoặc nhập khóa trước.");
            return;
        }

        String msg = readMessage(request, "verifyFileTxt", "verifyMessage", "txt");
        String e   = trim(request.getParameter("sigE"));
        String s   = trim(request.getParameter("sigS"));

        // Trả lại giá trị để hiển thị lại form
        request.setAttribute("verifyMessage", msg != null ? msg : trim(request.getParameter("verifyMessage")));
        request.setAttribute("verifyE", e);
        request.setAttribute("verifyS", s);

        if (msg == null) return;

        if (e.isEmpty() || s.isEmpty()) {
            request.setAttribute("error", "Vui lòng nhập đầy đủ cặp chữ ký (e, s).");
            return;
        }

        try {
            boolean valid = model.verify(msg, e, s);
            request.setAttribute("verifyResult", valid);
            if (valid) {
                request.setAttribute("successMsg", "Xác minh THÀNH CÔNG — Tài liệu toàn vẹn nguyên bản.");
            } else {
                request.setAttribute("error", "Xác minh THẤT BẠI — Chữ ký không khớp hoặc nội dung bị thay đổi.");
            }
        } catch (NumberFormatException nfe) {
            request.setAttribute("error", "Định dạng lỗi: Cặp chữ ký (e, s) phải là chuỗi HEX hợp lệ.");
        }
    }

    // ─────────────────────────────────────────────
    //  RESET
    // ─────────────────────────────────────────────
    private void handleReset(HttpServletRequest request, HttpSession session) {
        session.removeAttribute("schnorrModel");
        request.setAttribute("activeTab", "keygen");
        request.setAttribute("successMsg", "Đã đặt lại toàn bộ hệ thống. Vui lòng tạo khóa mới.");
    }

    // ─────────────────────────────────────────────
    //  HELPER: đọc message từ file hoặc textarea
    // ─────────────────────────────────────────────
    private String readMessage(HttpServletRequest request,
                               String filePart, String textParam, String allowedExt)
            throws Exception {
        Part part = request.getPart(filePart);
        String msg;

        if (part != null && part.getSize() > 0) {
            String fileName = part.getSubmittedFileName();
            if (fileName == null || !fileName.toLowerCase().endsWith("." + allowedExt)) {
                request.setAttribute("error",
                    "Chỉ chấp nhận file ." + allowedExt + ". File bạn chọn: " +
                    (fileName != null ? fileName : "(không xác định)"));
                return null;
            }
            msg = readPart(part);
        } else {
            msg = request.getParameter(textParam);
        }

        if (msg == null || msg.isBlank()) {
            request.setAttribute("error", "Vui lòng cung cấp nội dung văn bản hoặc tải lên file ." + allowedExt + ".");
            return null;
        }
        return msg;
    }

    private String readPart(Part part) throws IOException {
        try (BufferedReader reader = new BufferedReader(
                new InputStreamReader(part.getInputStream(), StandardCharsets.UTF_8))) {
            return reader.lines().collect(Collectors.joining("\n"));
        }
    }

    private void pushKeysToUI(HttpServletRequest req, SchnorrDigitalSignatureModel m) {
        req.setAttribute("pHex",       m.getPHex());
        req.setAttribute("qHex",       m.getQHex());
        req.setAttribute("gHex",       m.getGHex());
        req.setAttribute("privateKey", m.getPrivateKeyHex());
        req.setAttribute("publicKey",  m.getPublicKeyHex());
    }

    private void preserveManualInput(HttpServletRequest req,
                                     String p, String q, String g, String x) {
        req.setAttribute("pHex",       p);
        req.setAttribute("qHex",       q);
        req.setAttribute("gHex",       g);
        req.setAttribute("privateKey", x);
    }

    private SchnorrDigitalSignatureModel getModel(HttpSession session) {
        return (SchnorrDigitalSignatureModel) session.getAttribute("schnorrModel");
    }

    private String trim(String s) {
        return s != null ? s.trim() : "";
    }
}