package com.nle.editor.qa

class NleColorQaReportEmitter {

    fun emit(issues: List<NleColorQaIssue>): NleColorQaReport {
        val failed = issues.any {
            it.severity == NleColorQaSeverity.ERROR || it.severity == NleColorQaSeverity.RELEASE_BLOCKER
        }
        return NleColorQaReport(
            timestamp = System.currentTimeMillis(),
            passed = !failed,
            issues = issues
        )
    }
}
