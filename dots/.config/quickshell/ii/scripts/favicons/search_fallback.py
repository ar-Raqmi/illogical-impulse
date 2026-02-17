import sys
import urllib.request
import urllib.parse
import re
import json
import concurrent.futures

# User-Agent to avoid being blocked (looks like a standard browser)
HEADERS = {
    'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1'
}

def clean_domain(url):
    if not url: return None
    try:
        # Extract domain from URL
        match = re.search(r'https?://([^/]+)', url)
        if match:
            return match.group(1).replace("www.", "")
    except:
        pass
    return None

def search_duckduckgo_lite(query):
    try:
        encoded_query = urllib.parse.quote(query)
        # I love you duckduckgo, you make things so simple
        # because of basic html structure I can just regex the crap out of it
        url = f"https://lite.duckduckgo.com/lite/?q={encoded_query}"
        
        req = urllib.request.Request(url, headers=HEADERS)
        with urllib.request.urlopen(req, timeout=3) as response:
            html = response.read().decode('utf-8')
            
        links = re.findall(r'<a[^>]*class=[\'"]result-link[\'"][^>]*href=[\'"](.*?)[\'"]|<a[^>]*href=[\'"](.*?)[\'"][^>]*class=[\'"]result-link[\'"]', html)
        
        for link_tuple in links:
            raw_url = "".join(link_tuple)
            if "uddg=" in raw_url:
                parsed = urllib.parse.urlparse(raw_url)
                qs = urllib.parse.parse_qs(parsed.query)
                if 'uddg' in qs:
                    real_url = qs['uddg'][0]
                else:
                    continue
            else:
                real_url = raw_url

            if not real_url.startswith("http"): continue
            
            dom = clean_domain(real_url)
            if dom: return dom
                
        return None
    except:
        return None

def search_bing_mobile(query):
    try:
        encoded_query = urllib.parse.quote(query)
        url = f"https://www.bing.com/search?q={encoded_query}"
        
        req = urllib.request.Request(url, headers=HEADERS)
        with urllib.request.urlopen(req, timeout=3) as response:
            html = response.read().decode('utf-8')
            
        # Regex to find first result in Bing Mobile HTML
        # Usually inside class="b_algo" -> <h2> -> <a href="...">
        # Simplified: Look for http links that are not Bing's own
        links = re.findall(r'href=["\'](https?://[^"\']+)["\']', html)
        
        for link in links:
            if "microsoft.com" in link or "bing.com" in link or "msn.com" in link: continue
            
            dom = clean_domain(link)
            if dom: return dom
            
        return None
    except:
        return None

if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(1)
        
    query = sys.argv[1]
    # Clean query
    clean_query = re.sub(r"\s*[-|—|·]\s*(Mozilla Firefox|Brave|Google Chrome|Chromium|Vivaldi|Edge|Zen|Floorp|LibreWolf|Thorium|Waterfox|Mullvad|Tor Browser|Quickshell|Antigravity)\s*$", "", query, flags=re.IGNORECASE).strip()
    
    # Run searches in parallel
    results = {}
    with concurrent.futures.ThreadPoolExecutor() as executor:
        future_ddg = executor.submit(search_duckduckgo_lite, clean_query)
        future_bing = executor.submit(search_bing_mobile, clean_query)
        
        done, _ = concurrent.futures.wait([future_ddg, future_bing], timeout=3.5)
        
        if future_ddg in done: results['ddg'] = future_ddg.result()
        if future_bing in done: results['bing'] = future_bing.result()

    ddg_dom = results.get('ddg')
    bing_dom = results.get('bing')
    
    # Consensus Logic
    final_dom = None
    
    if ddg_dom and bing_dom:
        if ddg_dom == bing_dom:
            final_dom = ddg_dom # Full Agreement
        else:
            # Conflict: Prefer the one that contains the query keywords
            q_lower = clean_query.lower().replace(" ", "")
            score_ddg = 1 if q_lower in ddg_dom else 0
            score_bing = 1 if q_lower in bing_dom else 0
            
            if score_bing > score_ddg:
                final_dom = bing_dom
            else:
                final_dom = ddg_dom # Default to DDG reliability
    elif ddg_dom:
        final_dom = ddg_dom
    elif bing_dom:
        final_dom = bing_dom
        
    if final_dom:
        print(final_dom)
    else:
        sys.exit(1)
