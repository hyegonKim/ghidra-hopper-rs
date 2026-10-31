public final class RuntimeBranchesProbe {
    private static native void throwCapture(String library, String output);
    private static native void bufferCapture(String library, String output);
    private static native void branchCapture(String library, String output, boolean resolver);
    public static void main(String[] args) {
        if (args.length != 4) throw new IllegalArgumentException("probe counter image output-prefix");
        System.load(args[0]);
        throwCapture(args[1], args[3] + "-throw.json");
        bufferCapture(args[2], args[3] + "-buffer.json");
        branchCapture(args[1], args[3] + "-callback.json", false);
        branchCapture(args[1], args[3] + "-resolver.json", true);
    }
}
