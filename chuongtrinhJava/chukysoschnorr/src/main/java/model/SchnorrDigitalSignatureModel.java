package model;

import java.math.BigInteger;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;

public class SchnorrDigitalSignatureModel {

    private BigInteger p, q, g;
    private BigInteger privateKey;
    private BigInteger publicKey;

    private static final SecureRandom random = new SecureRandom();

    private int pBits = 512;
    private int qBits = 160;

    public SchnorrDigitalSignatureModel() {}

    // ═══════════════════════════════════════════════════════
    //  1. SINH KHÓA TỰ ĐỘNG
    // ═══════════════════════════════════════════════════════
    public void generateKeys() { generateKeys(pBits, qBits); }

    public void generateKeys(int pBitLength, int qBitLength) {
        this.pBits = pBitLength;
        this.qBits = qBitLength;

        q = BigInteger.probablePrime(qBitLength, random);

        int kBits = pBitLength - qBitLength;
        if (kBits < 1)
            throw new IllegalArgumentException("Kích thước p phải lớn hơn kích thước q.");

        BigInteger k;
        int attempt = 0;
        do {
            if (++attempt > 20_000)
                throw new IllegalStateException("Không thể sinh tham số p sau 20.000 lần thử.");
            k = new BigInteger(kBits, random).setBit(kBits - 1);
            p = k.multiply(q).add(BigInteger.ONE);
        } while (!p.isProbablePrime(80));

        BigInteger exp = p.subtract(BigInteger.ONE).divide(q);
        attempt = 0;
        do {
            if (++attempt > 10_000)
                throw new IllegalStateException("Không thể sinh bộ phát sinh g sau 10.000 lần thử.");
            BigInteger h = new BigInteger(p.bitLength() - 1, random).add(BigInteger.valueOf(2));
            g = h.modPow(exp, p);
        } while (g.equals(BigInteger.ONE));

        if (!g.modPow(q, p).equals(BigInteger.ONE))
            throw new IllegalStateException("g sinh ra không có bậc q — thử lại.");

        do {
            privateKey = new BigInteger(q.bitLength(), random);
        } while (privateKey.compareTo(BigInteger.ONE) <= 0 || privateKey.compareTo(q) >= 0);

        publicKey = g.modPow(privateKey.negate().mod(q), p);
    }

    // ═══════════════════════════════════════════════════════
    //  2. NHẬP KHÓA THỦ CÔNG
    // ═══════════════════════════════════════════════════════
    public static class ManualKeyResult {
        public String errorP, errorQ, errorG, errorX;
        public boolean success;
        public boolean hasAnyError() {
            return errorP != null || errorQ != null || errorG != null || errorX != null;
        }
    }

    public ManualKeyResult setKeysManual(
            String pHex, String qHex, String gHex, String xHex, String yHex) {

        ManualKeyResult result = new ManualKeyResult();

        BigInteger pVal = parseBigIntHex(pHex);
        BigInteger qVal = parseBigIntHex(qHex);
        BigInteger gVal = parseBigIntHex(gHex);
        BigInteger xVal = parseBigIntHex(xHex);

        if (pVal == null) result.errorP = "p phải là số HEX hợp lệ (chỉ chứa ký tự 0-9, A-F).";
        if (qVal == null) result.errorQ = "q phải là số HEX hợp lệ (chỉ chứa ký tự 0-9, A-F).";
        if (gVal == null) result.errorG = "g phải là số HEX hợp lệ (chỉ chứa ký tự 0-9, A-F).";
        if (xVal == null) result.errorX = "Khóa bí mật x phải là số HEX hợp lệ (chỉ chứa ký tự 0-9, A-F).";

        if (result.hasAnyError()) return result;

        if (!pVal.isProbablePrime(40))
            result.errorP = "p không phải số nguyên tố. Schnorr yêu cầu p là số nguyên tố lớn.";
        if (!qVal.isProbablePrime(40))
            result.errorQ = "q không phải số nguyên tố. Schnorr yêu cầu q là số nguyên tố (thường 160-256 bit).";
        if (result.errorP == null && result.errorQ == null)
            if (!pVal.subtract(BigInteger.ONE).mod(qVal).equals(BigInteger.ZERO))
                result.errorQ = "q không chia hết (p−1). Schnorr yêu cầu q | (p−1).";
        if (result.errorG == null) {
            if (gVal.compareTo(BigInteger.ONE) <= 0)
                result.errorG = "g phải lớn hơn 1.";
            else if (result.errorP == null && gVal.compareTo(pVal) >= 0)
                result.errorG = "g phải nhỏ hơn p.";
        }
        if (result.errorG == null && result.errorP == null && result.errorQ == null)
            if (!gVal.modPow(qVal, pVal).equals(BigInteger.ONE))
                result.errorG = "g không có bậc q trong Z*_p (g^q mod p ≠ 1).";
        if (result.errorX == null && result.errorQ == null) {
            if (xVal.compareTo(BigInteger.ONE) <= 0)
                result.errorX = "Khóa bí mật x phải lớn hơn 1.";
            else if (xVal.compareTo(qVal) >= 0)
                result.errorX = "Khóa bí mật x phải nhỏ hơn q.";
        }

        if (result.hasAnyError()) return result;

        this.p = pVal; this.q = qVal; this.g = gVal; this.privateKey = xVal;
        this.publicKey = (yHex != null && !yHex.isBlank())
                ? new BigInteger(yHex.trim(), 16)
                : gVal.modPow(xVal.negate().mod(qVal), pVal);

        result.success = true;
        return result;
    }

    // ═══════════════════════════════════════════════════════
    //  3. KÝ SỐ — LƯU LẠI r ĐỂ HỖ TRỢ XÁC MINH CHI TIẾT
    // ═══════════════════════════════════════════════════════

    // Lưu r của lần ký gần nhất để hỗ trợ phân biệt lỗi khi xác minh
    private BigInteger lastR = null;

    public BigInteger[] sign(String message) throws Exception {
        if (p == null || q == null || g == null || privateKey == null)
            throw new IllegalStateException("Chưa khởi tạo tham số khóa.");

        BigInteger k;
        do {
            k = new BigInteger(q.bitLength(), random);
        } while (k.compareTo(BigInteger.ONE) <= 0 || k.compareTo(q) >= 0);

        BigInteger r = g.modPow(k, p);
        lastR = r;  // lưu lại r

        BigInteger e = hash(message, r);
        BigInteger s = k.add(privateKey.multiply(e)).mod(q);
        return new BigInteger[]{ e, s };
    }

    // ═══════════════════════════════════════════════════════
    //  4. XÁC MINH — PHÂN BIỆT LỖI VĂN BẢN / LỖI CHỮ KÝ
    // ═══════════════════════════════════════════════════════

    public enum VerifyStatus {
        VALID,
        INVALID_SIGNATURE_E,     // Chữ ký e sai (ngoài phạm vi hoặc sai giá trị)
        INVALID_SIGNATURE_S,     // Chữ ký s sai (ngoài phạm vi)
        INVALID_SIGNATURE_BOTH,  // Cả e và s đều sai phạm vi
        INVALID_SIGNATURE_PAIR,  // e, s đúng định dạng nhưng cặp (e,s) không hợp lệ với nhau
        TAMPERED_MESSAGE,        // Chữ ký hợp lệ nhưng nội dung văn bản bị thay đổi
        INVALID_FORMAT           // HEX sai định dạng
    }

    public static class VerifyResult {
        public VerifyStatus status;
        public String detail;
        public VerifyResult(VerifyStatus status, String detail) {
            this.status = status; this.detail = detail;
        }
        public boolean isValid() { return status == VerifyStatus.VALID; }
    }

    /**
     * Xác minh chi tiết — phân biệt đúng từng loại lỗi:
     *
     * Thuật toán Schnorr verify:
     *   rv = g^s * y^e mod p
     *   ev = H(message || rv)
     *   Hợp lệ khi ev == e
     *
     * Để phân biệt "e sai" hay "văn bản sai":
     *   - Nếu s hợp lệ, tính rv từ s và publicKey
     *   - Tính ev_correct = H(message || rv)  ← hash với văn bản người dùng nhập
     *   - Nếu ev_correct == e → văn bản đúng nhưng (e,s) không khớp nhau → lỗi chữ ký
     *   - Nếu ev_correct != e → có thể văn bản sai hoặc cả chữ ký sai
     *   - Dùng thêm kiểm tra: tính rv2 = g^s * y^ev_correct mod p
     *     nếu hash(message || rv2) == ev_correct → cặp (s, message) nhất quán → e bị sai
     */
    public VerifyResult verifyDetailed(String message, String eHex, String sHex)
            throws Exception {

        if (p == null || q == null || g == null || publicKey == null)
            throw new IllegalStateException("Chưa khởi tạo tham số khóa công khai.");

        // ── Bước 1: Kiểm tra định dạng HEX ──
        BigInteger e = parseBigIntHex(eHex);
        BigInteger s = parseBigIntHex(sHex);

        if (e == null && s == null)
            return new VerifyResult(VerifyStatus.INVALID_FORMAT, "Cả e và s không phải HEX hợp lệ.");
        if (e == null)
            return new VerifyResult(VerifyStatus.INVALID_FORMAT, "Giá trị e không phải HEX hợp lệ.");
        if (s == null)
            return new VerifyResult(VerifyStatus.INVALID_FORMAT, "Giá trị s không phải HEX hợp lệ.");

        // ── Bước 2: Kiểm tra phạm vi [1, q-1] ──
        boolean eOutOfRange = e.compareTo(BigInteger.ZERO) <= 0 || e.compareTo(q) >= 0;
        boolean sOutOfRange = s.compareTo(BigInteger.ZERO) <= 0 || s.compareTo(q) >= 0;

        if (eOutOfRange && sOutOfRange)
            return new VerifyResult(VerifyStatus.INVALID_SIGNATURE_BOTH,
                "Cả e và s đều nằm ngoài phạm vi [1, q−1].");
        if (sOutOfRange)
            return new VerifyResult(VerifyStatus.INVALID_SIGNATURE_S,
                "Giá trị s nằm ngoài phạm vi [1, q−1].");
        // Ghi chú: eOutOfRange xử lý ở bước 4 bên dưới sau khi kiểm tra s trước

        // ── Bước 3: Tính rv = g^s * y^e mod p (dùng e người dùng nhập) ──
        BigInteger gs  = g.modPow(s, p);
        BigInteger ye  = publicKey.modPow(e, p);
        BigInteger rv  = gs.multiply(ye).mod(p);

        // ── Bước 4: Tính ev = H(message || rv) ──
        BigInteger ev = hash(message, rv);

        // Kết quả đúng hoàn toàn
        if (ev.equals(e))
            return new VerifyResult(VerifyStatus.VALID, "Chữ ký hợp lệ.");

        // ── Bước 5: Phân biệt lỗi — kỹ thuật kiểm tra chéo ──
        //
        // Thử tính lại với giả định "e đúng bằng ev" (tức là văn bản đúng, e sai):
        //   rv2 = g^s * y^ev mod p
        //   ev2 = H(message || rv2)
        //   Nếu ev2 == ev → cặp (s, message) nhất quán, chỉ có e bị sai
        //
        BigInteger ye2  = publicKey.modPow(ev, p);
        BigInteger rv2  = gs.multiply(ye2).mod(p);
        BigInteger ev2  = hash(message, rv2);

        if (ev2.equals(ev)) {
            // s và văn bản nhất quán với nhau → e bị nhập sai
            if (eOutOfRange)
                return new VerifyResult(VerifyStatus.INVALID_SIGNATURE_E,
                    "Giá trị e nằm ngoài phạm vi [1, q−1]. Chữ ký e bị sai hoặc bị thay đổi.");
            else
                return new VerifyResult(VerifyStatus.INVALID_SIGNATURE_E,
                    "Giá trị e sai. Văn bản và s nhất quán nhưng e không khớp. " +
                    "Hãy kiểm tra lại giá trị e đã copy đúng chưa.");
        }

        // s và văn bản không nhất quán → có thể văn bản bị đổi, hoặc cả 2 đều sai
        // Thử thêm: kiểm tra xem s có nhất quán với văn bản không
        // bằng cách giải ngược: nếu văn bản đúng thì ev = H(msg||rv), so sánh ev vs e
        // Kết luận: ev != e và ev2 != ev → hoặc văn bản sai hoặc cặp (e,s) đều sai

        if (eOutOfRange)
            return new VerifyResult(VerifyStatus.INVALID_SIGNATURE_E,
                "Giá trị e nằm ngoài phạm vi [1, q−1]. Chữ ký e bị sai hoặc bị thay đổi.");

        // Phân biệt thêm: nếu s rất khác ngẫu nhiên thì có thể văn bản bị đổi
        // Dùng heuristic cuối: thử hash với văn bản hiện tại và s, xem có ra e hợp lệ không
        // Không thể biết chắc → báo cả 2 khả năng, ưu tiên "cặp chữ ký sai"
        return new VerifyResult(VerifyStatus.INVALID_SIGNATURE_PAIR,
            "Cặp chữ ký (e, s) không hợp lệ với văn bản và khóa công khai này. " +
            "Có thể do: chữ ký bị sai/thay đổi, hoặc văn bản bị thay đổi sau khi ký.");
    }

    public boolean verify(String message, String eHex, String sHex) throws Exception {
        return verifyDetailed(message, eHex, sHex).isValid();
    }

    // ═══════════════════════════════════════════════════════
    //  5. HÀM BĂM
    // ═══════════════════════════════════════════════════════
    private BigInteger hash(String message, BigInteger r) throws Exception {
        MessageDigest sha = MessageDigest.getInstance("SHA-256");
        sha.update(message.getBytes(StandardCharsets.UTF_8));
        byte[] rBytes = r.toByteArray();
        if (rBytes.length > 1 && rBytes[0] == 0x00)
            rBytes = Arrays.copyOfRange(rBytes, 1, rBytes.length);
        sha.update(rBytes);
        return new BigInteger(1, sha.digest()).mod(q);
    }

    // ═══════════════════════════════════════════════════════
    //  6. RESET
    // ═══════════════════════════════════════════════════════
    public void reset() {
        p = null; q = null; g = null;
        privateKey = null; publicKey = null; lastR = null;
    }

    // ═══════════════════════════════════════════════════════
    //  7. TIỆN ÍCH
    // ═══════════════════════════════════════════════════════
    private BigInteger parseBigIntHex(String hex) {
        if (hex == null || hex.isBlank()) return null;
        try { return new BigInteger(hex.trim(), 16); }
        catch (NumberFormatException e) { return null; }
    }

    // ═══════════════════════════════════════════════════════
    //  8. GETTERS
    // ═══════════════════════════════════════════════════════
    public String getPHex()           { return p          != null ? p.toString(16).toUpperCase()          : ""; }
    public String getQHex()           { return q          != null ? q.toString(16).toUpperCase()          : ""; }
    public String getGHex()           { return g          != null ? g.toString(16).toUpperCase()          : ""; }
    public String getPrivateKeyHex()  { return privateKey != null ? privateKey.toString(16).toUpperCase() : ""; }
    public String getPublicKeyHex()   { return publicKey  != null ? publicKey.toString(16).toUpperCase()  : ""; }
    public BigInteger getPrivateKey() { return privateKey; }
    public BigInteger getPublicKey()  { return publicKey; }
    public int getPBits()             { return pBits; }
    public int getQBits()             { return qBits; }
    public boolean hasKeys()          { return privateKey != null && publicKey != null; }
}