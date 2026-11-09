export class ErrorUtil {
  static messageOf(error: Object): string {
    if (error instanceof Error) {
      return error.message;
    }
    return String(error);
  }
}
