namespace DexManager.Models
{
    public sealed class VirtualDisplayLease
    {
        // Loopback leases own a helper channel, not an overlay setting.
        public bool IsLoopback { get; set; }
        public string LoopbackSessionId { get; set; }
        public string Serial { get; set; }
        public int DisplayId { get; set; }
        public string PreviousOverlaySetting { get; set; }
        public string AppliedOverlaySetting { get; set; }
        public bool OwnsOverlaySetting { get; set; }
        public bool ReusedExistingDisplay { get; set; }
    }
}
