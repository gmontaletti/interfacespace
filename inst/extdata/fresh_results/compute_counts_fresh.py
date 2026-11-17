# Compute per-study and pooled counts from endorsed rows of the ten registers.
import csv, os, json
from collections import Counter
order = ['F05','F11','F20','F25','F50','F53','F58','F70','F73','F75']
def rd(p): return list(csv.DictReader(open(p))) if os.path.exists(p) else []
out = []
for sid in order:
    d = f'fresh/registers/{sid}/'
    F = {r['code']: r for r in rd(d+'findings.csv') if r['status'] == 'endorsed'}
    T = {r['new_finding']: r for r in rd(d+'transformations.csv') if r['status'] == 'endorsed'}
    C = {r['code']: r for r in rd(d+'claims.csv') if r['status'] == 'endorsed'}
    R = [r for r in rd(d+'relations.csv') if r['status'] == 'endorsed']
    # Rule 12 transformations (endorsed by A1 with a 'Rule 12' reason): the output finding
    # is qualitative data partitioned by a quantitative measure, so it is itself a root
    # (its own strand) in addition to the roots of made_from. Other transformations
    # (quantitizing, N-to-N models) pass on only the roots of made_from (workbook Check 1).
    R12 = set()
    for dec in rd(d+'decisions.csv'):
        if dec['action'] == 'endorse' and 'rule 12' in dec['reason'].lower():
            R12 |= {x[2:] for x in dec['rows'].split(';') if x.startswith('T:')}
    def roots(f, seen=()):
        if f in T and f not in seen:
            s = {f} if (f in R12 and f in F) else set()
            for m in T[f]['made_from'].split(';'):
                m = m.strip()
                if m: s |= roots(m, seen + (f,))
            return s
        return {f} if f in F else set()
    joint, bad = [], []
    for c, r in C.items():
        rs = set()
        for f in r['rests_on'].split(';'):
            f = f.strip()
            if f: rs |= roots(f)
        strands = {F[x]['strand'] for x in rs}
        if {'Q', 'N'} <= strands:
            joint.append(c)
            if r['fit'] in ('single-strand', ''): bad.append(c)
    bad_rel = [r['code'] for r in R if r['from'] not in C or r['to'] not in C]
    rel = set()
    for r in R: rel |= {r['from'], r['to']}
    rel &= set(C)
    clashes = [r['code'] for r in R if r['relation'] == 'clashes']
    unsupported = [c for c, r in C.items() if not r['rests_on'].strip()]
    fits = Counter(C[c]['fit'] for c in joint)
    allrows = sum(len(rd(d+f)) for f in ('findings.csv','claims.csv','relations.csv','transformations.csv'))
    rej = sum(1 for f in ('findings.csv','claims.csv','relations.csv','transformations.csv') for r in rd(d+f) if r['status']=='rejected')
    out.append(dict(study=sid, findings=len(F), findings_Q=sum(1 for x in F.values() if x['strand']=='Q'),
        findings_N=sum(1 for x in F.values() if x['strand']=='N'), transformations=len(T),
        claims=len(C), joint=len(joint), joint_codes=';'.join(sorted(joint, key=lambda x:int(x[1:]))),
        joint_fit=dict(fits), related=len(rel), related_share=round(100*len(rel)/len(C),1),
        relations=len(R), covers=sum(r['relation']=='covers' for r in R), backs=sum(r['relation']=='backs' for r in R),
        clashes=len(clashes), unsupported_claims=len(unsupported), rows_total=allrows, rows_rejected=rej,
        check_relations_to_nonendorsed=bad_rel, check_joint_with_single_fit=bad))
json.dump(out, open('fresh/counts_fresh.json','w'), indent=1)
hdr = ['study','findings','findings_Q','findings_N','transformations','claims','joint','joint_codes','related','related_share','relations','covers','backs','clashes','unsupported_claims','rows_total','rows_rejected']
with open('fresh/counts_by_study_fresh.csv','w',newline='') as fh:
    w = csv.DictWriter(fh, fieldnames=hdr, extrasaction='ignore'); w.writeheader(); w.writerows(out)
tc = sum(o['claims'] for o in out); tj = sum(o['joint'] for o in out); tr = sum(o['related'] for o in out)
for o in out:
    print(f"{o['study']:8} F{o['findings']:3}(Q{o['findings_Q']}/N{o['findings_N']}) T{o['transformations']} C{o['claims']:4} J{o['joint']:2} {o['joint_fit']} rel {o['related']}({o['related_share']}%) R{o['relations']} cov{o['covers']} back{o['backs']} clash{o['clashes']} unsup{o['unsupported_claims']} rows {o['rows_total']} rej {o['rows_rejected']} CHECK {o['check_relations_to_nonendorsed']} {o['check_joint_with_single_fit']}")
js = sorted(o['joint'] for o in out); rs = sorted(o['related_share'] for o in out)
print('POOLED claims', tc, 'joint', tj, f'({100*tj/tc:.1f}%)', 'related', tr, f'({100*tr/tc:.1f}%)', 'clashes', sum(o['clashes'] for o in out))
print('median joint per study', (js[4]+js[5])/2, 'range', js[0], js[-1], '| median related share', (rs[4]+rs[5])/2, 'range', rs[0], rs[-1])
