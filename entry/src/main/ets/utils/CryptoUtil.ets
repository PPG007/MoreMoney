import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { util } from '@kit.ArkTS';

export class AesResult {
  iv: Uint8Array = new Uint8Array(0);
  cipher: Uint8Array = new Uint8Array(0);
  tag: Uint8Array = new Uint8Array(0);
}

const IV_LENGTH: number = 12;
const TAG_LENGTH: number = 16;

export class CryptoUtil {
  static randomBytes(length: number): Uint8Array {
    return cryptoFramework.createRandom().generateRandomSync(length).data;
  }

  static async deriveKey(password: string, salt: Uint8Array, iterations: number): Promise<Uint8Array> {
    const kdf: cryptoFramework.Kdf = cryptoFramework.createKdf('PBKDF2|SHA256');
    const spec: cryptoFramework.PBKDF2Spec = {
      algName: 'PBKDF2',
      password: password,
      salt: salt,
      iterations: iterations,
      keySize: 32
    };
    const secret: cryptoFramework.DataBlob = await kdf.generateSecret(spec);
    return secret.data;
  }

  static base64(bytes: Uint8Array): string {
    return new util.Base64Helper().encodeToStringSync(bytes);
  }

  static fromBase64(text: string): Uint8Array {
    if (text.length === 0) {
      return new Uint8Array(0);
    }
    return new util.Base64Helper().decodeSync(text);
  }

  static utf8(text: string): Uint8Array {
    return new util.TextEncoder().encodeInto(text);
  }

  static text(bytes: Uint8Array): string {
    return new util.TextDecoder().decodeToString(bytes);
  }

  static hex(bytes: Uint8Array): string {
    let result: string = '';
    for (const value of bytes) {
      result = result.concat(value.toString(16).padStart(2, '0'));
    }
    return result;
  }

  static constantTimeEquals(a: Uint8Array, b: Uint8Array): boolean {
    if (a.length !== b.length) {
      return false;
    }
    let diff: number = 0;
    for (let i = 0; i < a.length; i++) {
      diff = diff | (a[i] ^ b[i]);
    }
    return diff === 0;
  }

  static async sha256(text: string): Promise<string> {
    const md: cryptoFramework.Md = cryptoFramework.createMd('SHA256');
    await md.update({ data: CryptoUtil.utf8(text) });
    const digest: cryptoFramework.DataBlob = await md.digest();
    return CryptoUtil.hex(digest.data);
  }

  static async aesGcmEncrypt(key: Uint8Array, plain: Uint8Array): Promise<AesResult> {
    const iv: Uint8Array = CryptoUtil.randomBytes(IV_LENGTH);
    const symKeyGenerator: cryptoFramework.SymKeyGenerator = cryptoFramework.createSymKeyGenerator('AES256');
    const symKey: cryptoFramework.SymKey = await symKeyGenerator.convertKey({ data: key });
    const params: cryptoFramework.GcmParamsSpec = {
      algName: 'GcmParamsSpec',
      iv: { data: iv },
      aad: { data: new Uint8Array(0) },
      authTag: { data: new Uint8Array(TAG_LENGTH) }
    };
    const cipher: cryptoFramework.Cipher = cryptoFramework.createCipher('AES256|GCM|NoPadding');
    await cipher.init(cryptoFramework.CryptoMode.ENCRYPT_MODE, symKey, params);
    const output: cryptoFramework.DataBlob = await cipher.doFinal({ data: plain });
    const data: Uint8Array = output.data;
    const body: Uint8Array = data.subarray(0, data.length - TAG_LENGTH);
    const tag: Uint8Array = data.subarray(data.length - TAG_LENGTH);
    const result: AesResult = new AesResult();
    result.iv = iv;
    result.cipher = body;
    result.tag = tag;
    return result;
  }

  static async aesGcmDecrypt(key: Uint8Array, iv: Uint8Array, cipherBytes: Uint8Array,
    tag: Uint8Array): Promise<Uint8Array> {
    const body: Uint8Array = cipherBytes;
    const symKeyGenerator: cryptoFramework.SymKeyGenerator = cryptoFramework.createSymKeyGenerator('AES256');
    const symKey: cryptoFramework.SymKey = await symKeyGenerator.convertKey({ data: key });
    const params: cryptoFramework.GcmParamsSpec = {
      algName: 'GcmParamsSpec',
      iv: { data: iv },
      aad: { data: new Uint8Array(0) },
      authTag: { data: tag }
    };
    const cipher: cryptoFramework.Cipher = cryptoFramework.createCipher('AES256|GCM|NoPadding');
    await cipher.init(cryptoFramework.CryptoMode.DECRYPT_MODE, symKey, params);
    const output: cryptoFramework.DataBlob = await cipher.doFinal({ data: body });
    return output.data;
  }
}
