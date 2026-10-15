import os,pathlib,re,subprocess,sys
root=pathlib.Path(__file__).resolve().parents[1]
exe=os.environ.get('STATA_BIN','/Applications/Stata/StataMP.app/Contents/MacOS/stata-mp')
for test in sys.argv[1:] or [str(p.relative_to(root)) for p in sorted((root/'tests').glob('test_*.do'))]:
 log=root/(pathlib.Path(test).stem+'.log')
 if log.exists(): log.unlink()
 subprocess.run([exe,'-b','do',test],cwd=root,timeout=240,check=True)
 s=log.read_text(errors='replace')
 if re.search(r'^r\([0-9]+\);',s,re.M) or 'TEST_PASS' not in s: print(s[-6500:]);sys.exit(1)
 print('PASS',test)
