return {
	-- tools
	{
		"mason-org/mason.nvim",
		opts = function(_, opts)
			vim.list_extend(opts.ensure_installed, {
				"stylua",
				"selene",
				"luacheck",
				"shellcheck",
				"shfmt",
				"tailwindcss-language-server",
				"typescript-language-server",
				"css-lsp",
			})
		end,
	},

	-- lsp servers
	{
		"neovim/nvim-lspconfig",
		opts = {
			inlay_hints = { enabled = false },
			---@type lspconfig.options
			servers = {
				cssls = {},
				tailwindcss = {
					root_dir = function(...)
						return require("lspconfig.util").root_pattern(".git")(...)
					end,
				},
				tsserver = {
					root_dir = function(...)
						return require("lspconfig.util").root_pattern(".git")(...)
					end,
					single_file_support = false,
					settings = {
						typescript = {
							inlayHints = {
								includeInlayParameterNameHints = "literal",
								includeInlayParameterNameHintsWhenArgumentMatchesName = false,
								includeInlayFunctionParameterTypeHints = true,
								includeInlayVariableTypeHints = false,
								includeInlayPropertyDeclarationTypeHints = true,
								includeInlayFunctionLikeReturnTypeHints = true,
								includeInlayEnumMemberValueHints = true,
							},
						},
						javascript = {
							inlayHints = {
								includeInlayParameterNameHints = "all",
								includeInlayParameterNameHintsWhenArgumentMatchesName = false,
								includeInlayFunctionParameterTypeHints = true,
								includeInlayVariableTypeHints = true,
								includeInlayPropertyDeclarationTypeHints = true,
								includeInlayFunctionLikeReturnTypeHints = true,
								includeInlayEnumMemberValueHints = true,
							},
						},
					},
				},
				html = {},
				yamlls = {
					settings = {
						yaml = {
							keyOrdering = false,
						},
					},
				},
				lua_ls = {
					-- enabled = false,
					single_file_support = true,
					settings = {
						Lua = {
							workspace = {
								checkThirdParty = false,
							},
							completion = {
								workspaceWord = true,
								callSnippet = "Both",
							},
							misc = {
								parameters = {
									-- "--log-level=trace",
								},
							},
							hint = {
								enable = true,
								setType = false,
								paramType = true,
								paramName = "Disable",
								semicolon = "Disable",
								arrayIndex = "Disable",
							},
							doc = {
								privateName = { "^_" },
							},
							type = {
								castNumberToInteger = true,
							},
							diagnostics = {
								disable = { "incomplete-signature-doc", "trailing-space" },
								-- enable = false,
								groupSeverity = {
									strong = "Warning",
									strict = "Warning",
								},
								groupFileStatus = {
									["ambiguity"] = "Opened",
									["await"] = "Opened",
									["codestyle"] = "None",
									["duplicate"] = "Opened",
									["global"] = "Opened",
									["luadoc"] = "Opened",
									["redefined"] = "Opened",
									["strict"] = "Opened",
									["strong"] = "Opened",
									["type-check"] = "Opened",
									["unbalanced"] = "Opened",
									["unused"] = "Opened",
								},
								unusedLocalExclude = { "_*" },
							},
							format = {
								enable = false,
								defaultConfig = {
									indent_style = "space",
									indent_size = "2",
									continuation_indent_size = "2",
								},
							},
						},
					},
				},
			},
			setup = {},
		},
	},
	{
		"neovim/nvim-lspconfig",
		init = function()
			-- Customização do keymap "gd" via LspAttach
			vim.api.nvim_create_autocmd("LspAttach", {
				callback = function(args)
					local client = vim.lsp.get_client_by_id(args.data.client_id)
					if client and client.server_capabilities.definitionProvider then
						vim.keymap.set("n", "gd", function()
							-- DO NOT RESUSE WINDOW
							require("telescope.builtin").lsp_definitions({ reuse_win = false })
						end, { buffer = args.buf, desc = "Goto Definition" })
					end
				end,
			})

			-- Organize e remove imports não utilizados ao salvar
			vim.api.nvim_create_autocmd("BufWritePre", {
				pattern = { "*.ts", "*.tsx", "*.js", "*.jsx" },
				callback = function(args)
					local bufnr = args.buf
					local clients = vim.lsp.get_clients({ bufnr = bufnr, name = "vtsls" })
					if #clients == 0 then
						return
					end
					local client = clients[1]

					local actions_to_run = {
						"source.removeUnused.ts",
						"source.organizeImports",
					}

					for _, action_kind in ipairs(actions_to_run) do
						local params = {
							textDocument = { uri = vim.uri_from_bufnr(bufnr) },
							range = {
								start = { line = 0, character = 0 },
								["end"] = { line = vim.api.nvim_buf_line_count(bufnr), character = 0 },
							},
							context = {
								only = { action_kind },
								diagnostics = {},
							},
						}
						local result = client.request_sync("textDocument/codeAction", params, 3000, bufnr)
						if result and result.result and #result.result > 0 then
							for _, action in ipairs(result.result) do
								-- vtsls usa resolveProvider: precisa resolver a ação para obter o edit
								if not action.edit and action.data then
									local resolved = client.request_sync("codeAction/resolve", action, 3000, bufnr)
									if resolved and resolved.result then
										action = resolved.result
									end
								end
								if action.edit then
									vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
								elseif action.command then
									client.request_sync("workspace/executeCommand", action.command, 3000, bufnr)
								end
							end
						end
					end
				end,
			})
		end,
	},
}
