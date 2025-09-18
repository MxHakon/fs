// ==UserScript==
// @name         Tiller Auto Typer - Optimized
// @namespace    http://tampermonkey.net/
// @version      6.0
// @description  Auto types letters - Press MINUS key to toggle
// @author       AutoTyper
// @match        https://tillerquest.tiller.blog/*
// @grant        none
// @run-at       document-end
// ==/UserScript==

(function() {
    'use strict';
    
    let autoTypeEnabled = false;
    let isTyping = false;
    let statusIndicator;
    let mistakesMade = 0;
    const maxMistakes = 2;
    
    function forceCreateUI() {
        const existing = document.getElementById('auto-typer-ui');
        if (existing) {
            existing.remove();
        }
        
        const indicator = document.createElement('div');
        indicator.id = 'auto-typer-ui';
        
        indicator.innerHTML = `
            <div style="font-size: 20px; font-weight: bold; margin-bottom: 10px;">🤖 AUTO TYPER</div>
            <div id="status-display" style="font-size: 16px; padding: 8px; background: rgba(255,255,255,0.2); border-radius: 5px; margin: 8px 0;">
                STATUS: OFF
            </div>
            <div id="letter-display" style="font-size: 14px; margin: 8px 0; color: yellow;">
                LETTER: Searching...
            </div>
            <div id="mistake-counter" style="font-size: 12px; margin: 5px 0; color: #ff9999;">
                MISTAKES: 0/2
            </div>
            <div style="font-size: 12px; margin-top: 10px; opacity: 0.9; line-height: 1.4;">
                Press <strong>-</strong> (minus) to toggle<br>
                Press <strong>=</strong> (equals) to stop
            </div>
        `;
        
        indicator.style.cssText = `
            position: fixed !important;
            top: 20px !important;
            right: 20px !important;
            width: 220px !important;
            background: linear-gradient(135deg, #1a1a2e, #16213e) !important;
            color: white !important;
            padding: 20px !important;
            border-radius: 15px !important;
            font-family: 'Arial', sans-serif !important;
            text-align: center !important;
            z-index: 999999999 !important;
            border: 3px solid #00ff41 !important;
            box-shadow: 0 0 25px rgba(0, 255, 65, 0.5) !important;
            display: block !important;
            visibility: visible !important;
            opacity: 1 !important;
            transform: none !important;
        `;
        
        const forceAppend = () => {
            try {
                if (document.body) {
                    document.body.appendChild(indicator);
                } else if (document.documentElement) {
                    document.documentElement.appendChild(indicator);
                } else {
                    document.appendChild(indicator);
                }
            } catch (e) {
                setTimeout(forceAppend, 500);
            }
        };
        
        forceAppend();
        
        setTimeout(() => {
            const check = document.getElementById('auto-typer-ui');
            if (check) {
                check.style.display = 'block';
                check.style.visibility = 'visible';
            } else {
                forceCreateUI();
            }
        }, 1000);
        
        return indicator;
    }
    
    function updateUI(letter = '', info = '') {
        if (!statusIndicator) {
            statusIndicator = forceCreateUI();
        }
        
        const statusDisplay = document.getElementById('status-display');
        const letterDisplay = document.getElementById('letter-display');
        const mistakeCounter = document.getElementById('mistake-counter');
        
        if (statusDisplay) {
            statusDisplay.textContent = autoTypeEnabled ? 'STATUS: ON ✅' : 'STATUS: OFF ❌';
            statusDisplay.style.background = autoTypeEnabled ? 'rgba(0,255,0,0.3)' : 'rgba(255,255,255,0.2)';
        }
        
        if (letterDisplay) {
            letterDisplay.textContent = letter ? `LETTER: "${letter}"` : 'LETTER: None found';
            letterDisplay.style.color = letter ? '#00ff00' : '#ffff00';
        }
        
        if (mistakeCounter) {
            mistakeCounter.textContent = `MISTAKES: ${mistakesMade}/${maxMistakes}`;
        }
        
        if (statusIndicator) {
            statusIndicator.style.borderColor = autoTypeEnabled ? '#00ff00' : '#00ff41';
        }
    }
    
    function findCurrentLetter() {
        const spans = document.querySelectorAll('span');
        
        for (let i = 0; i < spans.length; i++) {
            const span = spans[i];
            const text = span.textContent;
            
            if (text.length === 1) {
                const classes = span.className || '';
                const style = window.getComputedStyle(span);
                const bgColor = style.backgroundColor;
                
                const isGreen = classes.includes('bg-green-700') || 
                               classes.includes('bg-green') ||
                               bgColor.includes('rgb(21, 128, 61)') ||
                               bgColor.includes('green');
                
                if (!isGreen) {
                    if (text === ' ') {
                        updateUI('SPACE', `Found space at span ${i}`);
                        return ' ';
                    } else {
                        updateUI(text, `Found at span ${i}`);
                        return text;
                    }
                }
            }
        }
        
        updateUI('', 'No letter detected');
        return null;
    }
    
    function getKeyCode(char) {
        const codes = {
            ' ': 'Space',
            '(': 'Digit9',
            ')': 'Digit0',
            ',': 'Comma',
            '.': 'Period',
            '-': 'Minus',
            '=': 'Equal'
        };
        return codes[char] || `Key${char.toUpperCase()}`;
    }
    
    function typeChar(char) {
        if (char === '\b') {
            const activeEl = document.activeElement || document.body;
            activeEl.focus();
            
            const backspaceEvent = new KeyboardEvent('keydown', {
                key: 'Backspace',
                code: 'Backspace',
                keyCode: 8,
                which: 8,
                bubbles: true,
                cancelable: true,
                view: window
            });
            
            activeEl.dispatchEvent(backspaceEvent);
            
            const keyupEvent = new KeyboardEvent('keyup', {
                key: 'Backspace',
                code: 'Backspace',
                keyCode: 8,
                which: 8,
                bubbles: true,
                cancelable: true,
                view: window
            });
            
            activeEl.dispatchEvent(keyupEvent);
            return;
        }
        
        try {
            const activeEl = document.activeElement || document.body;
            activeEl.focus();
            
            if (document.execCommand) {
                document.execCommand('insertText', false, char);
                return;
            }
        } catch (e) {
        }
        
        const keyCode = char.charCodeAt(0);
        const activeEl = document.activeElement || document.body;
        
        const events = [
            new KeyboardEvent('keydown', {
                key: char,
                code: getKeyCode(char),
                keyCode: keyCode,
                which: keyCode,
                bubbles: true,
                cancelable: true,
                view: window
            }),
            new KeyboardEvent('keypress', {
                key: char,
                code: getKeyCode(char),
                keyCode: keyCode,
                which: keyCode,
                charCode: keyCode,
                bubbles: true,
                cancelable: true,
                view: window
            }),
            new KeyboardEvent('keyup', {
                key: char,
                code: getKeyCode(char),
                keyCode: keyCode,
                which: keyCode,
                bubbles: true,
                cancelable: true,
                view: window
            })
        ];
        
        events.forEach(event => activeEl.dispatchEvent(event));
    }
    
    function startAutoTyping() {
        if (isTyping) return;
        
        isTyping = true;
        mistakesMade = 0;
        
        const moderateSpeedType = () => {
            if (!autoTypeEnabled || !isTyping) {
                stopAutoTyping();
                return;
            }
            
            const letter = findCurrentLetter();
            if (letter) {
                const shouldMakeMistake = mistakesMade < maxMistakes && Math.random() < 0.08;
                
                if (shouldMakeMistake) {
                    const wrongLetters = 'abcdefghijklmnopqrstuvwxyz';
                    const wrongLetter = wrongLetters[Math.floor(Math.random() * wrongLetters.length)];
                    
                    if (wrongLetter !== letter.toLowerCase()) {
                        typeChar(wrongLetter);
                        mistakesMade++;
                        
                        const letterDisplay = document.getElementById('letter-display');
                        if (letterDisplay) {
                            letterDisplay.style.color = '#ff0000';
                            letterDisplay.textContent = `MISTAKE: ${wrongLetter}`;
                        }
                        updateUI();
                        
                        setTimeout(() => {
                            typeChar('\b');
                            setTimeout(() => {
                                typeChar(letter);
                                const letterDisplay = document.getElementById('letter-display');
                                if (letterDisplay) {
                                    letterDisplay.style.color = '#00ff00';
                                    letterDisplay.textContent = `CORRECTED: ${letter === ' ' ? 'SPACE' : letter}`;
                                }
                            }, 30);
                        }, 100);
                        
                        setTimeout(() => {
                            if (autoTypeEnabled && isTyping) {
                                requestAnimationFrame(moderateSpeedType);
                            }
                        }, 200);
                        return;
                    }
                }
                
                const displayLetter = letter === ' ' ? 'SPACE' : letter;
                typeChar(letter);
                
                const letterDisplay = document.getElementById('letter-display');
                if (letterDisplay) {
                    letterDisplay.style.color = '#00ff00';
                    letterDisplay.textContent = `TYPING: ${displayLetter}`;
                }
            }
            
            setTimeout(() => {
                if (autoTypeEnabled && isTyping) {
                    requestAnimationFrame(moderateSpeedType);
                }
            }, 80);
        };
        
        requestAnimationFrame(moderateSpeedType);
    }
    
    function stopAutoTyping() {
        isTyping = false;
    }
    
    function toggle() {
        autoTypeEnabled = !autoTypeEnabled;
        
        updateUI();
        
        if (autoTypeEnabled) {
            startAutoTyping();
        } else {
            stopAutoTyping();
        }
    }
    
    function setupKeyboard() {
        document.addEventListener('keydown', function(e) {
            if (e.key === '-' || e.code === 'Minus') {
                e.preventDefault();
                toggle();
            }
            else if (e.key === '=' || e.code === 'Equal') {
                e.preventDefault();
                autoTypeEnabled = false;
                stopAutoTyping();
                updateUI();
            }
        }, true);
    }
    
    function initialize() {
        statusIndicator = forceCreateUI();
        updateUI();
        
        setupKeyboard();
        
        setTimeout(() => {
            findCurrentLetter();
        }, 2000);
    }
    
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initialize);
    } else {
        setTimeout(initialize, 100);
    }
    
    setTimeout(initialize, 1000);
    setTimeout(initialize, 3000);
    
})();
