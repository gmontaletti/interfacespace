# Build decision_origin.csv for each study register (review item 11).
#
# The decisions table records who DECIDED (A1) but not who PROPOSED each
# decision. This script derives the proposer mechanically, by matching each
# decision of decisions.csv (action, rows, reason) against the proposal files
# kept in the register folder:
#   00_decision_proposal.json     A3 proposals (decision-proposal prompt)
#   00_consistency_proposal.json  A3 proposals (consistency prompt)
#   00_decision_final.json        A3 proposal as modified by the author
#   00_consistency_final.json     A3 consistency proposal as modified by the author
#
# Rules:
#   1. action + rows + reason equal an item of a *_proposal.json file
#      -> proposed_by A3, accepted "unchanged".
#   2. equal an item of a *_final.json file only
#      -> proposed_by A1, accepted "modified_by_author"; the note cites the A3
#         items of the matching *_proposal.json that share rows with it, or
#         states that A3 proposed no item on those rows.
#   3. no match in any file
#      -> proposed_by A4 (main session model; proposals written in the session
#         and confirmed by the author, no proposal file saved), accepted
#         "unchanged". Allowed only for the registers listed in SESSION_IDS;
#         elsewhere the script stops.
#
# decisions.csv is never modified (registers are append-only). The script
# appends the agent row A4 to agents.csv where A4 is used and absent.
#
# Usage (from recode_interface_space/ or with the registers folder as
# argument):
#   python3 _decision_origin.py [registers_dir]
import csv
import json
import os
import sys

REG = sys.argv[1] if len(sys.argv) > 1 else os.path.join(
    os.path.dirname(os.path.abspath(__file__)), 'registers')
SESSION_IDS = {'HLT-C2', 'HLT-C12', 'PA-2.4'}
PAIRS = (('00_decision_proposal.json', '00_decision_final.json'),
         ('00_consistency_proposal.json', '00_consistency_final.json'))
A4_ROW = ['A4', 'claude-opus-5-5 (main session)', 'model',
          'Main (orchestrating) session; wrote the first-round decision '
          'proposals before the decision-proposal and consistency prompts '
          'existed (no proposal file saved); the author A1 confirmed them. '
          'Used in decision_origin.csv.']
A4_NOTE = {'HLT-C2': ' In this register the code A3 of the tables was '
           'assigned to this session before the consistency pass; correction '
           'rows C19-C20 and R11-R21 come from this session, C21-C22 and '
           'R22-R28 from the consistency prompt (00_consistency_proposal.json).'}
HEADER = ['decision', 'proposed_by', 'accepted', 'source_file', 'note']


def key(item):
    return (item['action'], ';'.join(item['rows']), item['reason'])


def load(path):
    if not os.path.exists(path):
        return None
    with open(path, encoding='utf-8') as fh:
        return json.load(fh)['decisions']


def describe(items):
    return '; '.join(f"{i['action']} {';'.join(i['rows'])}" for i in items)


def origin_of(d, files):
    k = (d['action'], d['rows'], d['reason'])
    for prop, final in PAIRS:
        if files[prop] is not None and k in {key(i) for i in files[prop]}:
            return ['A3', 'unchanged', prop, '']
    for prop, final in PAIRS:
        if files[final] is None or k not in {key(i) for i in files[final]}:
            continue
        rows = set(d['rows'].split(';'))
        near = [i for i in files[prop] or [] if rows & set(i['rows'])]
        if near:
            changed = [lab for lab, ok in (
                ('rows', any(set(i['rows']) == rows for i in near)),
                ('action', any(i['action'] == d['action'] for i in near)),
                ('reason', any(i['reason'] == d['reason'] for i in near)))
                if not ok]
            note = (f'A3 proposed in {prop}: {describe(near)}; '
                    f'the author changed the {", ".join(changed)}.')
        else:
            note = (f'No A3 item on these rows in {prop}; '
                    'added at the author\'s request.')
        return ['A1', 'modified_by_author', final, note]
    return None


def main():
    ids = sorted(i for i in os.listdir(REG)
                 if os.path.isdir(os.path.join(REG, i)))
    for sid in ids:
        d = os.path.join(REG, sid)
        with open(os.path.join(d, 'decisions.csv'), encoding='utf-8') as fh:
            decs = list(csv.DictReader(fh))
        files = {f: load(os.path.join(d, f)) for pair in PAIRS for f in pair}
        out = []
        for dec in decs:
            o = origin_of(dec, files)
            if o is None:
                if sid not in SESSION_IDS:
                    sys.exit(f'{sid} {dec["code"]}: no proposal matches')
                o = ['A4', 'unchanged', 'none',
                     'Proposal written in the main session and confirmed '
                     'by the author; no proposal file saved.']
            out.append([dec['code']] + o)
        with open(os.path.join(d, 'decision_origin.csv'), 'w', newline='',
                  encoding='utf-8') as fh:
            w = csv.writer(fh, quoting=csv.QUOTE_ALL)
            w.writerow(HEADER)
            w.writerows(out)
        if any(r[1] == 'A4' for r in out):
            ap = os.path.join(d, 'agents.csv')
            with open(ap, encoding='utf-8') as fh:
                codes = [r['code'] for r in csv.DictReader(fh)]
            if 'A4' not in codes:
                with open(ap, 'a', newline='', encoding='utf-8') as fh:
                    row = A4_ROW[:3] + [A4_ROW[3] + A4_NOTE.get(sid, '')]
                    csv.writer(fh, quoting=csv.QUOTE_ALL).writerow(row)
        tally = {}
        for r in out:
            tally[(r[1], r[2])] = tally.get((r[1], r[2]), 0) + 1
        print(sid, len(out), tally)


if __name__ == '__main__':
    main()
