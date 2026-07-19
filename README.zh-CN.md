# Pebble

中文 | [English](./README.en.md)

Pebble 是一个基于 macOS 的桌面宠物应用。它可以让一个小宠物在 Dock 附近活动，并支持待机、行走等基础动画状态，同时支持默认资源包和用户自定义上传资源包。

本项目基于开源项目 [DockCat](https://github.com/Auwuua/DockCat) 修改开发。

## 项目简介

Pebble 的目标是提供一个轻量、可自定义的 macOS 桌面陪伴体验。用户可以使用 App 内置的默认宠物资源，也可以上传自己的宠物图片资源包，让桌面宠物以不同形象出现在桌面上。

当前项目仍处于开发和测试阶段，主要聚焦于桌宠动画、资源加载、自定义资源包处理和 macOS 桌面交互体验。

## 功能特性

- macOS 桌面宠物展示
- 支持 Dock 附近活动
- 支持待机与行走动画状态
- 内置默认宠物资源包
- 支持用户上传自定义宠物资源
- 支持本地资源加载与缓存
- 轻量化桌面陪伴体验

## 下载与安装

你可以在本仓库的 [Releases](../../releases) 页面下载最新的 macOS 测试版本。

当前版本说明：

- App 以 `.zip` 形式提供
- 当前为未签名测试版
- 首次打开时，macOS 可能提示“无法验证开发者”

如果 macOS 阻止打开，请尝试：

1. 解压下载的 `.zip` 文件；
2. 右键点击 `Pebble.app`；
3. 选择“打开”；
4. 在弹窗中再次确认打开。

由于当前版本尚未进行 Apple Developer ID 签名和 notarization，因此该提示属于正常现象。

## 从源码运行

### 环境要求

- macOS
- Xcode
- Swift

### 运行步骤

1. 克隆本仓库并进入项目目录：
git clone https://github.com/Eileen-111/Pebble.git
2. 使用 Xcode 打开项目文件：
cd Pebble
3. 如果项目文件位于子目录中，请在 Finder 中找到 DockCat.xcodeproj 后双击打开。
open DockCat.xcodeproj
4. 在 Xcode 中选择 App Target。
5. 点击 Run 构建并运行项目。

## 项目结构

当前项目主要结构如下：

DockCat.xcodeproj：Xcode 项目文件

DockCat/：主要源码与资源文件

DockCat/Assets.xcassets：App 图标及部分资源文件

README.md：项目说明文档

README.en.md：英文版 README

LICENSE：许可证文件

.gitignore：Git 忽略规则

## 项目来源与致谢

Pebble 基于开源项目 [DockCat](https://github.com/Auwuua/DockCat) 修改开发。DockCat 是由 Auwuua 开发的 macOS 程序坞桌面陪伴小猫应用。

本项目在 DockCat 的基础上进行了二次开发，主要修改包括：宠物资源、默认角色资源、动画表现、资源加载逻辑，以及用户自定义资源包处理逻辑等。

感谢原作者开源 DockCat 项目。

## 许可证

本项目基于 [DockCat](https://github.com/Auwuua/DockCat) 修改开发。原项目采用 PolyForm Noncommercial License。

本项目遵循原 DockCat 项目的许可证条款。除非获得原项目作者的单独授权，本项目及其修改版本不得用于商业用途。

如果你公开分发本项目或其修改版本，请保留原始许可证和版权声明，提供原项目链接，并清楚说明本项目基于 DockCat 修改开发及主要修改内容。

原项目地址：https://github.com/Auwuua/DockCat

角色图片及第三方素材不包含在本许可证范围内，其版权归原权利方所有。
