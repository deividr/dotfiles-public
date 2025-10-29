return {
	-- Configuração para markdownlint
	{
		"neovim/nvim-lspconfig",
		opts = function(_, opts)
			-- Configuração do markdownlint
			opts.servers = opts.servers or {}
			opts.servers.marksman = opts.servers.marksman or {}
			
			-- Desabilitar ou ajustar diagnósticos para markdown
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "markdown",
				callback = function()
					-- Desabilitar spell check para markdown
					vim.opt_local.spell = false
					vim.opt_local.spelllang = ""
					
					-- Ajustar severidade dos diagnósticos
					vim.diagnostic.config({
						virtual_text = {
							severity = { min = vim.diagnostic.severity.WARN },
							-- Não mostrar virtual text para markdown hints
						},
						signs = {
							severity = { min = vim.diagnostic.severity.WARN },
						},
						underline = {
							severity = { min = vim.diagnostic.severity.WARN },
						},
						float = {
							border = "rounded",
							source = "always",
							severity_sort = true,
						},
					}, vim.api.nvim_get_current_buf())

					-- Desabilitar completamente para arquivos CHANGELOG
					local filename = vim.fn.expand("%:t")
					if filename:match("^CHANGELOG") then
						vim.diagnostic.enable(false, { bufnr = 0 })
					end
				end,
			})
		end,
	},

	-- Configuração do conform.nvim para formatação de markdown
	{
		"stevearc/conform.nvim",
		optional = true,
		opts = {
			formatters = {
				["markdown-toc"] = {
					condition = function(_, ctx)
						for _, line in ipairs(vim.api.nvim_buf_get_lines(ctx.buf, 0, -1, false)) do
							if line:find("<!%-%- toc %-%->") then
								return true
							end
						end
					end,
				},
				["markdownlint-cli2"] = {
					condition = function(_, ctx)
						local diag = vim.diagnostic.get(ctx.buf)
						return #diag > 0
					end,
				},
			},
			formatters_by_ft = {
				markdown = { "prettier", "markdownlint-cli2", "markdown-toc" },
			},
		},
	},

	-- Configuração do nvim-lint para desabilitar markdownlint em certos casos
	{
		"mfussenegger/nvim-lint",
		optional = true,
		opts = function(_, opts)
			-- Remover ou ajustar markdownlint
			if opts.linters_by_ft and opts.linters_by_ft.markdown then
				-- Desabilitar markdownlint para markdown
				opts.linters_by_ft.markdown = vim.tbl_filter(function(linter)
					return linter ~= "markdownlint"
				end, opts.linters_by_ft.markdown)
			end

			-- Ou configurar markdownlint com regras personalizadas
			opts.linters = opts.linters or {}
			opts.linters.markdownlint = {
				args = {
					"--disable",
					"MD013", -- line length
					"MD041", -- first line heading
					"MD033", -- inline HTML
					"MD034", -- bare URLs
					"--",
				},
			}
		end,
	},
}

