#!/usr/bin/env python3
"""Inspect completed RC15 CI bytes; publish one create-only candidate ref."""
import argparse, ast, base64, hashlib, io, json, os, re, struct, subprocess, tarfile, time
import urllib.error, urllib.parse, urllib.request, zipfile
from pathlib import Path, PurePosixPath
REPO="Renatasy83/PullOverPro"
SOURCE="becd7123fec59177684f52cfd58fc8aea03e23e3"
MAC_RUN,MAC_JOB,MAC_ARTIFACT=42997965218,130446679699,13844653812
LINUX_RUN,LINUX_JOB,LINUX_ARTIFACT=42997965200,130446679776,13844443315
MAC_DIGEST="sha256:ee59acd1a5832a028d5cbcf8b89e8a76016f06d6d2691539202f75cd0f407834"
LINUX_DIGEST="sha256:78f9fac4ed8c4d7779cd60215718a11a6b113b0f13f55e5a130360d5ea5b4915"
DEB_NAME="com.renatasy83.pulloverpro.diagnostic_1.0.14~rc15_iphoneos-arm64.deb"
VERSION="1.0.14~rc15"
BRANCH="release-candidates/1.0.14-rc15"
PREFIX=BRANCH+"/"
PROTECTED=[{"ref":"heads/main","sha":"af336d84a6b4812e6b6406af87803fb15bf29c3b"},{"ref":"heads/stable/verified-rc2-safari-source-free-classic-reuse","sha":"e5c6e53f659109d77d78a5a99f7139899a978991"},{"ref":"heads/stable/verified-rc12-messenger586-geometry","sha":"8f0c64f5ce82913b8cb99ef7bcecf0de6b307fa2"},{"ref":"heads/stable/verified-rc13-messenger586-minimize","sha":"c87589dc45eb4d5039081eff7015f48ad1ff4a7e"},{"ref":"heads/release-candidates/1.0.13-rc14","sha":"b111008864ba8545ff8f1b92398bb0d1e6a30873"},{"ref":"heads/release-candidates/1.0.12-rc13","sha":"7f77890d4229375c83050683eb0ef6718b90b9ef"},{"ref":"heads/release-candidates/1.0.11-rc12","sha":"c08bc044455f6a6d359626891ede89915c75a34c"},{"ref":"heads/release-candidates/1.0.10-rc11","sha":"fe48837528401c61e81372d1ebc1e012ad4cfbd1"},{"ref":"heads/release-candidates/1.0.9-rc10","sha":"50b1390a373052f90622b47376a59aaa92c56898"}]
TOKEN=os.environ["RC15_TOKEN"]
API="https://api.github.com/repos/"+REPO
HEADERS={"Authorization":"Bearer "+TOKEN,"Accept":"application/vnd.github+json",
 "X-GitHub-Api-Version":"2022-11-28","User-Agent":"PPO-reviewed-RC15-archive"}
parser=argparse.ArgumentParser()
parser.add_argument("--source-dir",type=Path,required=True)
parser.add_argument("--output-dir",type=Path,required=True)
args=parser.parse_args()
src,out=args.source_dir.resolve(),args.output_dir.resolve()
out.mkdir(parents=True,exist_ok=True)
class NoRedirect(urllib.request.HTTPRedirectHandler):
 def redirect_request(self,req,fp,code,msg,headers,newurl): return None
opener=urllib.request.build_opener(NoRedirect())
def api(path,method="GET",payload=None):
 data=json.dumps(payload).encode() if payload is not None else None
 headers=dict(HEADERS)
 if data is not None: headers["Content-Type"]="application/json"
 try:
  with opener.open(urllib.request.Request(API+path,data=data,headers=headers,method=method),timeout=45) as response:
   return json.load(response)
 except urllib.error.HTTPError as exc:
  raise RuntimeError("GitHub API "+method+" "+path+" returned "+str(exc.code)) from None
def resource(path,limit):
 # Authentication goes only to api.github.com; signed storage is anonymous.
 try:
  with opener.open(urllib.request.Request(API+path,headers=HEADERS),timeout=45) as response:
   data=response.read(limit+1)
 except urllib.error.HTTPError as exc:
  if exc.code not in (301,302,303,307,308):
   raise RuntimeError("GitHub download returned "+str(exc.code)) from None
  location=exc.headers.get("Location","")
  parsed=urllib.parse.urlparse(location)
  assert parsed.scheme=="https" and parsed.netloc and not parsed.username and not parsed.password
  try:
   with urllib.request.urlopen(urllib.request.Request(location,headers={"User-Agent":"PPO-reviewed-RC15-archive"}),timeout=45) as response:
    data=response.read(limit+1)
  except Exception:
   raise RuntimeError("Signed download failed; URL intentionally omitted") from None
 assert len(data)<=limit
 return data
def checked_run(run_id,job_id):
 run=api("/actions/runs/"+str(run_id)); job=api("/actions/jobs/"+str(job_id))
 assert run["head_sha"]==SOURCE and run["status"]=="completed" and run["conclusion"]=="success"
 assert job["run_id"]==run_id and job["status"]=="completed" and job["conclusion"]=="success"
 assert not any(s.get("conclusion")=="failure" for s in job.get("steps",[]))
 return {"run":run_id,"job":job_id,"conclusion":"success"}
def checked_zip(run_id,artifact_id,digest,prefix):
 meta=api("/actions/artifacts/"+str(artifact_id))
 inventory=api("/actions/runs/"+str(run_id)+"/artifacts?per_page=100")["artifacts"]
 assert len(inventory)==1 and inventory[0]["id"]==artifact_id
 assert meta["workflow_run"]["id"]==run_id and meta["workflow_run"]["head_sha"]==SOURCE
 assert meta["name"]==prefix+SOURCE and not meta["expired"] and meta["digest"]==digest
 size=meta["size_in_bytes"]; assert 0<size<=32*1024*1024
 data=resource("/actions/artifacts/"+str(artifact_id)+"/zip",size)
 assert len(data)==size and "sha256:"+hashlib.sha256(data).hexdigest()==digest
 z=zipfile.ZipFile(io.BytesIO(data)); names=z.namelist()
 assert len(names)==len(set(names)) and z.testzip() is None
 assert sum(i.file_size for i in z.infolist())<=64*1024*1024
 for item in z.infolist():
  p=PurePosixPath(item.filename)
  assert not p.is_absolute() and ".." not in p.parts and "\\" not in item.filename
  assert ((item.external_attr>>16)&0o170000)!=0o120000 and item.file_size<=16*1024*1024
 return meta,z
def preserved_refs():
 for item in PROTECTED:
  assert api("/git/ref/"+item["ref"])["object"]["sha"]==item["sha"],item["ref"]
assert subprocess.check_output(["git","-C",str(src),"rev-parse","HEAD"],text=True).strip()==SOURCE
mac_run=checked_run(MAC_RUN,MAC_JOB); linux_run=checked_run(LINUX_RUN,LINUX_JOB)
mac_meta,mac_zip=checked_zip(MAC_RUN,MAC_ARTIFACT,MAC_DIGEST,"PullOverPro-1.0.14-rc15-")
linux_meta,linux_zip=checked_zip(LINUX_RUN,LINUX_ARTIFACT,LINUX_DIGEST,"PullOverPro-RC15-linux-evidence-")

assert not any(n.endswith(".deb") for n in linux_zip.namelist())
paths=[n for n in linux_zip.namelist() if n.endswith("LINUX_VALIDATION.json")]
assert len(paths)==1
linux_report=json.loads(linux_zip.read(paths[0]))
assert linux_report["commit"]==SOURCE and linux_report["portableSuitesPassed"]==13
assert linux_report["sourceAndLifecyclePassed"] and linux_report["crossTargetStaticAnalysis"]
assert not linux_report["rootlessCrossBuild"] and linux_report["nativeSuiteCount"]==40
assert not linux_report["abiProbe"]["supportsRequiredABI"] and linux_report["abiProbe"]["cpuSubtype"]=="0x2"
debs=[n for n in mac_zip.namelist() if n.endswith(".deb")]
assert debs==["packages/"+DEB_NAME]
data=mac_zip.read(debs[0]); deb=out/DEB_NAME; deb.write_bytes(data)
diagnostics=out/"diagnostics"; diagnostics.mkdir(exist_ok=True)
for name in mac_zip.namelist():
 parts=PurePosixPath(name).parts
 if name.endswith("/") or not parts or parts[0]!="diagnostics": continue
 assert len(parts)==2
 target=diagnostics/parts[1]; assert not target.exists()
 target.write_bytes(mac_zip.read(name))
report=json.loads((diagnostics/"VALIDATION.json").read_text())
assert report["commit"]==SOURCE
markers=None
for node in ast.parse((src/"scripts/write-validation-report.py").read_text()).body:
 if isinstance(node,ast.Assign) and any(isinstance(t,ast.Name) and t.id=="markers" for t in node.targets):
  markers=ast.literal_eval(node.value)
assert isinstance(markers,dict) and len(markers)==40
assert len(report["successful_test_logs"])==40 and set(report["successful_test_logs"])==set(markers)
native_markers={}
for filename,marker in markers.items():
 text=(diagnostics/filename).read_text()
 assert text.count(marker)==1,filename
 assert not re.search(r"^(FAIL:|AddressSanitizer:|UndefinedBehaviorSanitizer:|runtime error:)",text,re.M)
 native_markers[filename]=text.strip().splitlines()[-1]
assert "Menu binding tests passed: 378 checks;" in native_markers["menu-binding-tests.log"]
assert SOURCE in (diagnostics/"build-environment.txt").read_text()
digest=hashlib.sha256(data).hexdigest()
assert digest in (diagnostics/"SHA256SUMS").read_text() and digest in report["sha256sums"]
mac_log=resource("/actions/jobs/"+str(MAC_JOB)+"/logs",2*1024*1024).decode()
warnings=[line for line in mac_log.splitlines() if "warning:" in line]
assert len(warnings)==12 and all("-multiply_defined is obsolete" in l for l in warnings)
assert not re.search(r"\berror:",mac_log)
analysis_logs=sorted(diagnostics.glob("*analysis.log"))
assert len(analysis_logs)==13 and all(not p.read_text().strip() for p in analysis_logs)
assert all(marker in mac_log for marker in markers.values())
outputs=[]
for index,command in enumerate([
 ["python3",str(src/"scripts/verify.py"),str(deb)],
 ["python3",str(src/"scripts/verify-linux-package.py"),str(deb)]]):
 result=subprocess.run(command,cwd=src,text=True,capture_output=True,check=True)
 outputs.append(result.stdout)
 (out/("inspection-"+str(index)+".log")).write_text(result.stdout+result.stderr)
inspection=json.loads(outputs[1])
assert len(inspection["checkedBinaries"])==6 and not inspection["runtimeTest"] and not inspection["signatureTrustVerified"]
payload=subprocess.check_output(["dpkg-deb","--fsys-tarfile",str(deb)])
root_markers={}
with tarfile.open(fileobj=io.BytesIO(payload)) as archive:
 for member in archive:
  if not member.isfile(): continue
  name=member.name.removeprefix("./")
  image_data=archive.extractfile(member).read()
  if image_data[:4]!=b"\xca\xfe\xba\xbe": continue
  for index in range(struct.unpack_from(">I",image_data,4)[0]):
   _,subtype,offset,length,_=struct.unpack_from(">IIIII",image_data,8+20*index)
   image=image_data[offset:offset+length]
   if name.endswith("PullOverProDiagnostic.dylib"):
    for marker in (b"presentationActionsMenu\0",b"actionsMenuModel\0",
     b"bindSource:owner:destination:setter:\0",b"classicMenuAssignmentCount\0",b"host-1.0.14.json\0"):
     assert marker in image,(name,hex(subtype),marker)
    root_markers[name+":"+hex(subtype)]="original model/binder/counter/version present"
   if name.endswith("PPOMessengerReturnAgent.dylib") or name.endswith("/ppo-bridge"):
    for marker in (b"741517f9808a10ac225c6490d2af5bd835ff56b112464c5d53ce670d7ff92e30\0",
     b"354b8abc3acd00ae3a16f48e3b0156f1497be49742f6dc1db3753c13bbc89b9f\0",
     b"585.0.0\0",b"586.0.0\0",b"1101076820\0",b"1105932679\0",
     b"reviewed-messenger585-warm-trial\0",b"reviewed-messenger586-warm-trial\0"):
     assert marker in image,(name,hex(subtype),marker)
assert len(root_markers)==2
preserved_refs()
assert api("/git/matching-refs/heads/"+BRANCH)==[],"Archive already exists; never update it"
blob_sha=hashlib.sha1(b"blob "+str(len(data)).encode()+b"\0"+data).hexdigest()
evidence={
 "source":SOURCE,"version":VERSION,"macOSActions":mac_run,
 "macArtifact":{"id":MAC_ARTIFACT,"bytes":mac_meta["size_in_bytes"],"digest":mac_meta["digest"]},
 "linuxActions":linux_run,"linuxArtifact":{"id":LINUX_ARTIFACT,"bytes":linux_meta["size_in_bytes"],"digest":linux_meta["digest"]},
 "deb":{"name":DEB_NAME,"bytes":len(data),"sha256":digest,"gitBlobSHA":blob_sha},
 "originalCIReport":report,"nativeTestMarkers":native_markers,"menuBindingChecks":378,
 "analysisLogs":13,"analysisDiagnostics":[],"obsoleteLinkerWarnings":12,
 "sixBinaryInspection":inspection,"rootMarkers":root_markers,"linuxEvidence":linux_report,
 "inspectionEnvironment":"Separate Ubuntu archive workflow; interactive executor unavailable",
 "automationCommit":os.environ["RC15_AUTOMATION_SHA"],"archiveWorkflowRun":os.environ["GITHUB_RUN_ID"],
 "scope":"Retained original menu model and copy-safe original-source/weak-owner/weak-target binding; actual assignments counted and anchor setters idempotent.",
 "causeLimit":"Unsupported RC14 cross-button identity under copy semantics; actual iOS26 rebind/dismiss cadence not proven by old logs.",
 "retainedGuards":["exact585/586 warm profiles","schema5","15second default/120root/125agent",
  "manualKeep/currentroot/window/scene/framework/owner/lock/render/cleanup/quarantine","same public hitTest bounds"],
 "deviceRuntimeTested":False,"signatureTrustVerified":False,"dopamineEllekitCompatibilityConfirmed":False,
 "requiredPhoneGate":"Manual install/respring; normalMessenger/PPO Sertar; Xmenu Keep within15s, stable menu and live session beyond15s. Then remaining NewTerm retract/reveal/input/menuMinimize/Restore/X/normalMessenger. Sendhost1.0.14 andinterface1.0.14; stop on flicker/black/refusal.",
 "recovery":"Verified RC13 stablec87589dc45eb4d5039081eff7015f48ad1ff4a7e/archive7f77890d4229375c83050683eb0ef6718b90b9ef; main/stables/olderarchives preserved."
}

readme="\n".join([
 "# PullOver Pro 1.0.14~rc15 — copy-safe Messenger menu candidate","",
 "Tested source "+SOURCE+". macOS run42997965218 passed40 native suites, including378 production menu-binding checks, analysis, rootless Theos/SDK16.5 arm64+modernarm64e build. Linux42997965200 passed13 portable/source/lifecycle/static suites and correctly skipped unsupportedABI packaging.","",
 "This separate Ubuntu archive job checked provenance/digest/CRC,40 markers, payload/filter/lifecycle/license, six actual binaries/signature bounds and model/binder markers before publishing. Interactive executor was unavailable. No physical UIKit or signature trust claim.","",
 "DEB "+DEB_NAME+", bytes "+str(len(data))+", SHA256 "+digest+".","",
 "Repairs unsupported cross-button pointer identity despite UIKit copying menus. Retains original model, binds semantic identity only, counts actual assignments and avoids no-op anchor setters. Profile/Agent/schema5/hitTest/15default120root125agent unchanged; no autoKeep/privateAPI/cold launch/capextension.","",
 "One phone gate: manuallyinstall/respring, normalMessenger thenPPO Sertar, within15s longpressX selectKeep. Check stable menu and live session beyond15s. If successful, remaining NewTerm retract/reveal/input/menuMinimize/Restore/tapX/normalMessenger in same session. Send /var/mobile/Library/Logs/PullOverPro/host-1.0.14.json and interface-1.0.14.json. Stop on flicker/black/refusal; no repeated2minute/otherapp/cold tests or personal Data.","",
 "Verified RC13 recovery archive7f77890d4229375c83050683eb0ef6718b90b9ef retained. No automaticphoneaction/personal-data deletion/other-tweak change. GPL-3.0/c1d3r attribution and exact source preserved. Recovery /var/mobile/.ppo_disable/manualrespring orknownDopaminewithoutinjection/uninstallonlyPPO ifunusable.",""
])
blob=api("/git/blobs","POST",{"encoding":"base64","content":base64.b64encode(data).decode()})
assert blob["sha"]==blob_sha
entries=[
 {"path":PREFIX+DEB_NAME,"mode":"100644","type":"blob","sha":blob_sha},
 {"path":PREFIX+"SHA256SUMS","mode":"100644","type":"blob","content":digest+"  "+DEB_NAME+"\n"},
 {"path":PREFIX+"VALIDATION.json","mode":"100644","type":"blob","content":json.dumps(evidence,indent=2)+"\n"},
 {"path":PREFIX+"README.md","mode":"100644","type":"blob","content":readme}]
tree=api("/git/trees","POST",{"tree":entries})
commit=api("/git/commits","POST",{"message":"Archive verified RC15 candidate from completed CI [skip ci]",
 "tree":tree["sha"],"parents":[SOURCE]})
# Atomic create only. A conflict is an error, never an update or force.
api("/git/refs","POST",{"ref":"refs/heads/"+BRANCH,"sha":commit["sha"]})
preserved_refs()
raw_url="https://raw.githubusercontent.com/"+REPO+"/"+commit["sha"]+"/"+PREFIX+DEB_NAME
raw=None
for attempt in range(3):
 try:
  with urllib.request.urlopen(raw_url,timeout=45) as response: raw=response.read(len(data)+1)
  break
 except urllib.error.HTTPError as exc:
  if exc.code!=404 or attempt==2: raise
  time.sleep(2)
assert raw==data and hashlib.sha256(raw).hexdigest()==digest
result={
 "source":SOURCE,"version":VERSION,"archive":commit["sha"],"branch":BRANCH,"url":raw_url,
 "debBytes":len(data),"debSHA256":digest,"blobSHA":blob_sha,
 "macArtifact":MAC_ARTIFACT,"macZIPBytes":mac_meta["size_in_bytes"],"macZIPDigest":mac_meta["digest"],
 "linuxArtifact":LINUX_ARTIFACT,"linuxZIPBytes":linux_meta["size_in_bytes"],"linuxZIPDigest":linux_meta["digest"],
 "nativeSuites":40,"portableSuites":13,"menuBindingChecks":378,
 "analysisLogs":13,"analyzerDiagnostics":0,"obsoleteLinkerWarnings":12,
 "rawDownloadVerified":True,"protectedRefsPreserved":True,"runtimeTested":False,
 "automationCommit":os.environ["RC15_AUTOMATION_SHA"],"archiveWorkflowRun":os.environ["GITHUB_RUN_ID"]}
(out/"ARCHIVE_RESULT.json").write_text(json.dumps(result,indent=2)+"\n")
print("RC15_ARCHIVE_RESULT="+json.dumps(result,separators=(",",":")))
