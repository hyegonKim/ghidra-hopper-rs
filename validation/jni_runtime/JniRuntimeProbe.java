public final class JniRuntimeProbe {
    private static native void capture(String library, String output) throws Exception;
    public static void main(String[] args) throws Exception {
        if (args.length != 3) throw new IllegalArgumentException("probe.so target.so output.json");
        System.load(args[0]);
        capture(args[1], args[2]);
    }
}
