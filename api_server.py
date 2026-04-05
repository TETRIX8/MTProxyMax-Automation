import subprocess, re, uvicorn
from fastapi import FastAPI, HTTPException, Header
app = FastAPI()
API_TOKEN = 'MTProxyMaxSecretToken123'
def clean_ansi(text): return re.compile(r'\x1B(?:[@-Z\\-_]|\\[[0-?]*[ -/]*[@-~])').sub('', text)
def run_command(cmd):
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        if result.returncode != 0: return {'error': clean_ansi(result.stderr.strip())}
        output = clean_ansi(result.stdout).strip()
        if 'issued:' in output:
            label = output.split(':')[-1].strip()
            link_res = subprocess.run(f'mtproxymax secret link {label}', shell=True, capture_output=True, text=True)
            link = clean_ansi(link_res.stdout).strip()
            return {'link': link, 'label': label}
        return {'output': output}
    except Exception as e: return {'error': str(e)}
@app.get('/get-test')
async def get_test(authorization: str = Header(None)):
    if authorization != f'Bearer {API_TOKEN}': raise HTTPException(status_code=401, detail='Unauthorized')
    return run_command('mtproxymax-pool get-test')
@app.get('/get-regular')
async def get_regular(label: str, period: str = '', authorization: str = Header(None)):
    if authorization != f'Bearer {API_TOKEN}': raise HTTPException(status_code=401, detail='Unauthorized')
    return run_command(f'mtproxymax-pool get-regular {label} "{period}"')
if __name__ == '__main__': uvicorn.run(app, host='0.0.0.0', port=8000)
