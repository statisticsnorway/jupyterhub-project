# This script scans the installed R-packges for security issues.
# It requires that the oyestR-package is installed:
# https://github.com/sonatype-nexus-community/oysteR

library("oysteR")
audit = audit_installed_r_pkgs()
vulns = get_vulnerabilities(audit)
print(vulns)

if (nrow(vulns) > 0) {
    quit(save = "no", status = 1, runLast = FALSE)
}
