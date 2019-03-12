<%@ webservice language="C#" class="PackageInstaller" %>
using System;
using System.Configuration;
using System.IO;
using System.Web.Services;
using System.Xml;
using Sitecore.Data.Engines;
using Sitecore.Install.Files;
using Sitecore.Install.Framework;
using Sitecore.Install.Items;
using Sitecore.SecurityModel;
using Sitecore.Update;
using Sitecore.Update.Installer;
using Sitecore.Update.Installer.Utils;
using Sitecore.Update.Utils;
using log4net;
using log4net.Config;

[WebService(Namespace = "http://tempuri.org/")]
[WebServiceBinding(ConformsTo = WsiProfiles.BasicProfile1_1)]
[System.ComponentModel.ToolboxItem(false)]
public class PackageInstaller : System.Web.Services.WebService
{
    [WebMethod(Description = "Installs a Sitecore Zip or Update Package.")]
    public void InstallPackage(string path)
    {
        var file = new FileInfo(path);  
        if (!file.Exists)
        {
            throw new ApplicationException(string.Format("Cannot access path '{0}'.", path));
        }

        if (file.Extension == ".update")
        {
            InstallUpdatePackage(path);
        }
        else
        {
            InstallZipPackage(path);
        }
    }

    private void InstallUpdatePackage(string path)
    {
        var log = LogManager.GetLogger("root");
        XmlConfigurator.Configure((XmlElement)ConfigurationManager.GetSection("log4net"));

        using (new SecurityDisabler())
        {
            var installer = new DiffInstaller(UpgradeAction.Upgrade);
            var view = UpdateHelper.LoadMetadata(path);
            
            string historyPath;
            bool hasPostAction;
            var entries = installer.InstallPackage(path, InstallMode.Install, log, out hasPostAction, out historyPath);
            installer.ExecutePostInstallationInstructions(path, historyPath, InstallMode.Install, view, log, ref entries);
            UpdateHelper.SaveInstallationMessages(entries, historyPath);
        }
    }

    private void InstallZipPackage(string path)
    {
        Sitecore.Context.SetActiveSite("shell");

        using (new SecurityDisabler())  
        {  
            using (new SyncOperationContext())  
            {  
                var context = new SimpleProcessingContext();
                var options = new Sitecore.Install.Utils.BehaviourOptions(Sitecore.Install.Utils.InstallMode.Overwrite, Sitecore.Install.Utils.MergeMode.Undefined);
                context.AddAspect(new DefaultItemInstallerEvents(options));  
                context.AddAspect(new DefaultFileInstallerEvents(true));  
          
                var installer = new Sitecore.Install.Installer();  
                installer.InstallPackage(path, context);  
            }  
        }  
    }
}