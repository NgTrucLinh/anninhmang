package model;

import java.math.BigInteger;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;

public class SchnorrDigitalSignatureModel {

    private BigInteger p, q, g;
    private BigInteger privateKey; // x
    private BigInteger publicKey;  // y = g^(-x) mod p

    private static final SecureRandom random = new SecureRandom();

    public SchnorrDigitalSignatureModel() {}

    // ─────────────────────────────────────────────
    //  SINH KHÓA TỰ ĐỘNG
    // ─────────────────────────────────────────────
    public void generateKeys() {
        // 1. Tạo q (160-bit) nguyên tố
        q = BigInteger.probablePrime(160, random);

        // 2. Tạo p (512-bit) sao cho p = k*q + 1 là số nguyên tố
        BigInteger k;
        int attempt = 0;
        do {
            if (++attempt > 10_000)
                throw new IllegalStateException("Không thể sinh tham số p sau 10.000 lần thử.");
            k = new BigInteger(352, random).setBit(351);
            p = k.multiply(q).add(BigInteger.ONE);
        } while (!p.isProbablePrime(80));

        // 3. Tạo g có bậc q mod p
        BigInteger exp = p.subtract(BigInteger.ONE).divide(q);
        attempt = 0;
        do {
            if (++attempt > 10_000)
                throw new IllegalStateException("Không thể sinh bộ phát sinh g sau 10.000 lần thử.");
            BigInteger h = new BigInteger(p.bitLength() - 1, random).add(BigInteger.valueOf(2));
            g = h.modPow(exp, p);
        } while (g.equals(BigInteger.ONE));

        // Xác nhận bậc đúng: g^q ≡ 1 (mod p)
        if (!g.modPow(q, p).equals(BigInteger.ONE))
            throw new IllegalStateException("g sinh ra không có bậc q — thử lại.");

        // 4. Khóa bí mật x: 1 < x < q
        do {
            privateKey = new BigInteger(q.bitLength(), random);
        } while (privateKey.compareTo(BigInteger.ONE) <= 0
              || privateKey.compareTo(q) >= 0);

        // 5. Khóa công khai y = g^(-x) mod p
        publicKey = g.modPow(privateKey.negate().mod(q), p);
    }

    // ─────────────────────────────────────────────
    //  NHẬP KHÓA THỦ CÔNG (CÓ KIỂM TRA HỢP LỆ)
    // ─────────────────────────────────────────────
    public void setKeysManual(String pHex, String qHex, String gHex, String xHex, String yHex)
            throws IllegalArgumentException {
        BigInteger pVal = new BigInteger(pHex, 16);
        BigInteger qVal = new BigInteger(qHex, 16);
        BigInteger gVal = new BigInteger(gHex, 16);
        BigInteger xVal = new BigInteger(xHex, 16);

        // Kiểm tra tính hợp lệ tối thiểu
        if (xVal.compareTo(BigInteger.ONE) <= 0 || xVal.compareTo(qVal) >= 0)
            throw new IllegalArgumentException("Khóa bí mật x phải thỏa: 1 < x < q.");
        if (gVal.compareTo(BigInteger.ONE) <= 0 || gVal.compareTo(pVal) >= 0)
            throw new IllegalArgumentException("Bộ phát sinh g phải thỏa: 1 < g < p.");
        if (!gVal.modPow(qVal, pVal).equals(BigInteger.ONE))
            throw new IllegalArgumentException("g không có bậc q mod p — tham số nhóm không hợp lệ.");

        this.p = pVal;
        this.q = qVal;
        this.g = gVal;
        this.privateKey = xVal;
        this.publicKey = (yHex != null && !yHex.isBlank())
                ? new BigInteger(yHex, 16)
                : gVal.modPow(xVal.negate().mod(qVal), pVal);
    }

    // ─────────────────────────────────────────────
    //  RESET (xóa toàn bộ trạng thái)
    // ─────────────────────────────────────────────
    public void reset() {
        p = null; q = null; g = null;
        privateKey = null; publicKey = null;
    }

    // ─────────────────────────────────────────────
    //  KÝ SỐ
    // ─────────────────────────────────────────────
    public BigInteger[] sign(String message) throws Exception {
        if (p == null || q == null || g == null || privateKey == null)
            throw new IllegalStateException("Chưa khởi tạo tham số khóa.");

        BigInteger k;
        do {
            k = new BigInteger(q.bitLength(), random);
        } while (k.compareTo(BigInteger.ONE) <= 0 || k.compareTo(q) >= 0);

        BigInteger r = g.modPow(k, p);
        BigInteger e = hash(message, r);
        BigInteger s = k.add(privateKey.multiply(e)).mod(q);
        return new BigInteger[]{ e, s };
    }

    // ─────────────────────────────────────────────
    //  XÁC MINH
    // ─────────────────────────────────────────────
    public boolean verify(String message, String eHex, String sHex) throws Exception {
        if (p == null || q == null || g == null || publicKey == null)
            throw new IllegalStateException("Chưa khởi tạo tham số khóa công khai.");

        BigInteger e = new BigInteger(eHex.trim(), 16);
        BigInteger s = new BigInteger(sHex.trim(), 16);

        // Kiểm tra phạm vi chữ ký
        if (e.compareTo(BigInteger.ZERO) <= 0 || e.compareTo(q) >= 0)
            return false;
        if (s.compareTo(BigInteger.ZERO) <= 0 || s.compareTo(q) >= 0)
            return false;

        // r_v = g^s * y^e mod p
        BigInteger gs  = g.modPow(s, p);
        BigInteger ye  = publicKey.modPow(e, p);
        BigInteger rv  = gs.multiply(ye).mod(p);
        BigInteger ev  = hash(message, rv);

        return ev.equals(e);
    }

    // ─────────────────────────────────────────────
    //  HÀM BĂM (ĐÃ SỬA: loại bỏ byte 0x00 đứng đầu)
    // ─────────────────────────────────────────────
    private BigInteger hash(String message, BigInteger r) throws Exception {
        MessageDigest sha = MessageDigest.getInstance("SHA-256");
        sha.update(message.getBytes(StandardCharsets.UTF_8));

        // FIX: toByteArray() thêm byte 0x00 đứng đầu khi MSB = 1 → loại bỏ để
        //      hash nhất quán giữa ký và xác minh, tránh false negative ~50%
        byte[] rBytes = r.toByteArray();
        if (rBytes.length > 1 && rBytes[0] == 0x00)
            rBytes = Arrays.copyOfRange(rBytes, 1, rBytes.length);

        sha.update(rBytes);
        return new BigInteger(1, sha.digest()).mod(q);
    }

    // ─────────────────────────────────────────────
    //  GETTERS
    // ─────────────────────────────────────────────
    public String getPHex()          { return p          != null ? p.toString(16).toUpperCase()          : ""; }
    public String getQHex()          { return q          != null ? q.toString(16).toUpperCase()          : ""; }
    public String getGHex()          { return g          != null ? g.toString(16).toUpperCase()          : ""; }
    public String getPrivateKeyHex() { return privateKey != null ? privateKey.toString(16).toUpperCase() : ""; }
    public String getPublicKeyHex()  { return publicKey  != null ? publicKey.toString(16).toUpperCase()  : ""; }
    public BigInteger getPrivateKey(){ return privateKey; }
    public BigInteger getPublicKey() { return publicKey; }
    public boolean hasKeys()         { return privateKey != null && publicKey != null; }
}