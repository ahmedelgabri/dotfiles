-- Abolish abbreviations.

if vim.fn.exists ':Abolish' == 0 then
  return
end

vim.cmd [[Abolish teh{,n}                                      the{}]]
vim.cmd [[Abolish taht                                         that]]
vim.cmd [[Abolish adn                                          and]]
vim.cmd [[Abolish waht                                         what]]
vim.cmd [[Abolish ret{run,unr}                                 return]]
vim.cmd [[Abolish delte{,e}                                    delete{}]]

vim.cmd [[Abolish {despa,sepe}rat{e,es,ed,ing,ely,ion,ions,or} {despe,sepa}rat{}]]
vim.cmd [[Abolish {,in}consistant{,ly}                         {}consistent{}]]
vim.cmd [[Abolish lan{gauge,gue,guege,guegae,ague,agueg}       language]]
vim.cmd [[Abolish delimeter{,s}                                delimiter{}]]
vim.cmd [[Abolish {,non}existan{ce,t}                          {}existen{}]]
vim.cmd [[Abolish d{e,i}screp{e,a}nc{y,ies}                    d{i}screp{a}nc{}]]
vim.cmd [[Abolish {,un}nec{ce,ces,e}sar{y,ily}                 {}nec{es}sar{}]]
vim.cmd [[Abolish persistan{ce,t,tly}                          persisten{}]]
vim.cmd [[Abolish {,ir}releven{ce,cy,t,tly}                    {}relevan{}]]
vim.cmd [[Abolish cal{a,e}nder{,s}                             cal{e}ndar{}]]
vim.cmd [[Abolish reproducable                                 reproducible]]
vim.cmd [[Abolish retreive                                     retrieve]]
vim.cmd [[Abolish compeletly                                   completely]]
vim.cmd [[Abolish unfor{t}unatly                               unfortunately]]
vim.cmd [[Abolish funciton{,ed,s}                              function{}]]
