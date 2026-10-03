using System.IO;
using System.Runtime.Serialization.Json;
using System.Text;
using DexManager.Models;
using DexManager.Services;
using Xunit;

namespace DexManager.Tests
{
    public class PhonePreviewSettingsTests
    {
        [Fact]
        public void ExistingSettingsWithoutPhonePreviewChoiceKeepOverlayMode()
        {
            var settings = AppSettings.CreateDefault();
            settings.GetOrCreateDeviceRunSettings("legacy-phone");
            var serializer = new DataContractJsonSerializer(typeof(AppSettings));
            string json;
            using (var stream = new MemoryStream())
            {
                serializer.WriteObject(stream, settings);
                json = Encoding.UTF8.GetString(stream.ToArray());
            }
            json = json.Replace(",\"HidePhonePreview\":false", string.Empty);
            Assert.DoesNotContain("HidePhonePreview", json);

            using (var stream = new MemoryStream(Encoding.UTF8.GetBytes(json)))
            {
                var loaded = (AppSettings)serializer.ReadObject(stream);
                loaded.EnsureDefaults();
                Assert.False(loaded.VirtualDisplay.HidePhonePreview);
                Assert.False(loaded.GetOrCreateDeviceRunSettings("legacy-phone")
                    .VirtualDisplay.HidePhonePreview);
                Assert.True(loaded.Scrcpy.TurnScreenOff);
            }
        }

        [Fact]
        public void PhonePreviewChoiceIsClonedFromTemplateAndIndependentPerDevice()
        {
            var settings = AppSettings.CreateDefault();
            settings.VirtualDisplay.HidePhonePreview = true;
            var phoneA = settings.GetOrCreateDeviceRunSettings("phone-a");
            var phoneB = settings.GetOrCreateDeviceRunSettings("phone-b");
            Assert.True(phoneA.VirtualDisplay.HidePhonePreview);
            Assert.True(phoneB.VirtualDisplay.HidePhonePreview);

            phoneA.VirtualDisplay.HidePhonePreview = false;
            settings.EnsureDefaults();
            Assert.False(phoneA.VirtualDisplay.HidePhonePreview);
            Assert.True(phoneB.VirtualDisplay.HidePhonePreview);
            Assert.True(settings.VirtualDisplay.HidePhonePreview);
            Assert.True(phoneA.Scrcpy.TurnScreenOff);
            Assert.True(phoneB.Scrcpy.TurnScreenOff);
        }

        [Fact]
        public void SaveLoadAndUnrelatedSettingsUpdatePreserveChoiceAndScreenOffPreference()
        {
            var root = Path.Combine(Path.GetTempPath(),
                "DXManager.PhonePreviewTest." + System.Guid.NewGuid().ToString("N"));
            Directory.CreateDirectory(root);
            try
            {
                var service = new SettingsService(new LogService(), root);
                var settings = AppSettings.CreateDefault();
                var phoneA = settings.GetOrCreateDeviceRunSettings("phone-a");
                var phoneB = settings.GetOrCreateDeviceRunSettings("phone-b");
                phoneA.VirtualDisplay.HidePhonePreview = true;
                phoneA.Scrcpy.TurnScreenOff = true;
                phoneB.Scrcpy.TurnScreenOff = false;
                service.Save(settings);

                var loaded = service.Load();
                service.UpdateAndSave(loaded, candidate =>
                    candidate.GetOrCreateDeviceRunSettings("phone-a").Scrcpy.BitRate = "12M");
                loaded = service.Load();
                var loadedA = loaded.GetOrCreateDeviceRunSettings("phone-a");
                var loadedB = loaded.GetOrCreateDeviceRunSettings("phone-b");
                Assert.True(loadedA.VirtualDisplay.HidePhonePreview);
                Assert.True(loadedA.Scrcpy.TurnScreenOff);
                Assert.Equal("12M", loadedA.Scrcpy.BitRate);
                Assert.False(loadedB.VirtualDisplay.HidePhonePreview);
                Assert.False(loadedB.Scrcpy.TurnScreenOff);
                Assert.True(loadedA.SingleWindowSlots[0].TurnScreenOff);
            }
            finally
            {
                Directory.Delete(root, true);
            }
        }
    }
}
