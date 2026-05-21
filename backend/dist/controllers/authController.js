"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.getMe = exports.setPushSetting = exports.getPushSetting = exports.setDevToken = exports.checkCodeResetPassword = exports.createCodeResetPassword = exports.resetPassword = exports.changePassword = exports.changeInfoAfterSignup = exports.logout = exports.login = exports.signup = void 0;
const bcryptjs_1 = __importDefault(require("bcryptjs"));
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const db_1 = __importDefault(require("../config/db"));
const JWT_SECRET = process.env.JWT_SECRET || 'army_ecommerce_secret_key_2026_Quang_Trung_Soldier';
const JWT_EXPIRES_IN = (process.env.JWT_EXPIRES_IN || '7d');
const signup = async (req, res) => {
    const { phone_number, password, uuid } = req.body;
    if (!phone_number || !password || !uuid) {
        return res.status(200).json({
            code: '1002',
            message: 'Parameter is not enough',
            data: null,
        });
    }
    if (password.length < 6) {
        return res.status(200).json({
            code: '1004',
            message: 'Password must be at least 6 characters',
            data: null,
        });
    }
    try {
        const existingUser = await db_1.default.user.findUnique({
            where: { phone_number },
        });
        if (existingUser) {
            return res.status(200).json({
                code: '9996',
                message: 'User existed',
                data: null,
            });
        }
        const hashedPassword = await bcryptjs_1.default.hash(password, 10);
        const user = await db_1.default.user.create({
            data: {
                phone_number,
                password: hashedPassword,
                username: phone_number, // Mặc định username là sđt
            },
        });
        // Tạo JWT token ngay khi signup xong hoặc trả về thông tin user
        const token = jsonwebtoken_1.default.sign({ sub: user.id, username: user.phone_number, role: user.role }, JWT_SECRET, { expiresIn: JWT_EXPIRES_IN });
        return res.status(201).json({
            code: '1000',
            message: 'OK',
            data: {
                id: user.id,
                phone_number: user.phone_number,
                username: user.username,
                token: token,
            },
        });
    }
    catch (error) {
        console.error('Signup error:', error);
        return res.status(200).json({
            code: '9999',
            message: 'Exception occurred',
            data: null,
        });
    }
};
exports.signup = signup;
const login = async (req, res) => {
    const { phone_number, password } = req.body;
    if (!phone_number || !password) {
        return res.status(200).json({
            code: '1002',
            message: 'Parameter is not enough',
            data: null,
        });
    }
    try {
        const user = await db_1.default.user.findUnique({
            where: { phone_number },
        });
        if (!user) {
            return res.status(200).json({
                code: '9995',
                message: 'Tài khoản chưa đăng ký hoặc mật khẩu không chính xác',
                data: null,
            });
        }
        const isMatch = await bcryptjs_1.default.compare(password, user.password);
        if (!isMatch) {
            return res.status(200).json({
                code: '9995',
                message: 'Tài khoản chưa đăng ký hoặc mật khẩu không chính xác',
                data: null,
            });
        }
        const token = jsonwebtoken_1.default.sign({ sub: user.id, username: user.phone_number, role: user.role }, JWT_SECRET, { expiresIn: JWT_EXPIRES_IN });
        // Cập nhật trạng thái online
        await db_1.default.user.update({
            where: { id: user.id },
            data: { online: 1 },
        });
        return res.status(201).json({
            code: '1000',
            message: 'OK',
            data: {
                id: user.id,
                phonenumber: user.phone_number,
                username: user.username,
                email: user.email,
                firstname: user.firstname,
                lastname: user.lastname,
                address: user.address,
                city: user.city,
                avatar: user.avatar,
                cover_image: user.cover_image,
                cover_image_web: user.cover_image_web,
                status: user.status,
                listing: user.listing,
                online: 1,
                token: token,
            },
        });
    }
    catch (error) {
        console.error('Login error:', error);
        return res.status(200).json({
            code: '9999',
            message: 'Exception occurred',
            data: null,
        });
    }
};
exports.login = login;
const logout = async (req, res) => {
    if (req.user) {
        try {
            await db_1.default.user.update({
                where: { id: req.user.id },
                data: { online: 0 },
            });
        }
        catch (e) {
            // Ignored
        }
    }
    return res.status(201).json({
        code: '1000',
        message: 'OK',
        data: null,
    });
};
exports.logout = logout;
const changeInfoAfterSignup = async (req, res) => {
    const { username, avatar } = req.body;
    if (!username) {
        return res.status(200).json({
            code: '1002',
            message: 'Parameter is not enough',
            data: null,
        });
    }
    if (!req.user) {
        return res.status(200).json({
            code: '9998',
            message: 'Token is invalid.',
            data: null,
        });
    }
    try {
        const updatedUser = await db_1.default.user.update({
            where: { id: req.user.id },
            data: {
                username,
                avatar: avatar || undefined,
            },
        });
        return res.status(201).json({
            code: '1000',
            message: 'OK',
            data: {
                id: updatedUser.id,
                phonenumber: updatedUser.phone_number,
                username: updatedUser.username,
                avatar: updatedUser.avatar,
            },
        });
    }
    catch (error) {
        console.error('changeInfoAfterSignup error:', error);
        return res.status(200).json({
            code: '9999',
            message: 'Exception occurred',
            data: null,
        });
    }
};
exports.changeInfoAfterSignup = changeInfoAfterSignup;
const changePassword = async (req, res) => {
    const { password, new_password } = req.body;
    if (!password || !new_password) {
        return res.status(200).json({
            code: '1002',
            message: 'Parameter is not enough',
            data: null,
        });
    }
    if (!req.user) {
        return res.status(200).json({
            code: '9998',
            message: 'Token is invalid.',
            data: null,
        });
    }
    try {
        const user = await db_1.default.user.findUnique({
            where: { id: req.user.id },
        });
        if (!user) {
            return res.status(200).json({
                code: '9995',
                message: 'User not found',
                data: null,
            });
        }
        const isMatch = await bcryptjs_1.default.compare(password, user.password);
        if (!isMatch) {
            return res.status(200).json({
                code: '1004',
                message: 'Password incorrect',
                data: null,
            });
        }
        const hashedNewPassword = await bcryptjs_1.default.hash(new_password, 10);
        await db_1.default.user.update({
            where: { id: req.user.id },
            data: { password: hashedNewPassword },
        });
        return res.status(201).json({
            code: '1000',
            message: 'OK',
            data: null,
        });
    }
    catch (error) {
        console.error('changePassword error:', error);
        return res.status(200).json({
            code: '9999',
            message: 'Exception occurred',
            data: null,
        });
    }
};
exports.changePassword = changePassword;
const resetPassword = async (req, res) => {
    const { phone_number, password } = req.body;
    if (!phone_number || !password) {
        return res.status(200).json({
            code: '1002',
            message: 'Parameter is not enough',
            data: null,
        });
    }
    if (password.length < 6) {
        return res.status(200).json({
            code: '1004',
            message: 'Parameter value is invalid',
            data: null,
        });
    }
    try {
        const user = await db_1.default.user.findUnique({
            where: { phone_number },
        });
        if (!user) {
            return res.status(200).json({
                code: '9995',
                message: 'User not found',
                data: null,
            });
        }
        const hashedNewPassword = await bcryptjs_1.default.hash(password, 10);
        const updatedUser = await db_1.default.user.update({
            where: { id: user.id },
            data: {
                password: hashedNewPassword,
                online: 1,
            },
        });
        const token = jsonwebtoken_1.default.sign({ sub: updatedUser.id, username: updatedUser.phone_number, role: updatedUser.role }, JWT_SECRET, { expiresIn: JWT_EXPIRES_IN });
        return res.status(201).json({
            code: '1000',
            message: 'OK',
            data: {
                id: updatedUser.id,
                phonenumber: updatedUser.phone_number,
                username: updatedUser.username,
                email: updatedUser.email,
                firstname: updatedUser.firstname,
                lastname: updatedUser.lastname,
                address: updatedUser.address,
                city: updatedUser.city,
                avatar: updatedUser.avatar,
                cover_image: updatedUser.cover_image,
                cover_image_web: updatedUser.cover_image_web,
                status: updatedUser.status,
                listing: updatedUser.listing,
                online: 1,
                token: token,
            },
        });
    }
    catch (error) {
        console.error('resetPassword error:', error);
        return res.status(200).json({
            code: '9999',
            message: 'Exception occurred',
            data: null,
        });
    }
};
exports.resetPassword = resetPassword;
const createCodeResetPassword = async (req, res) => {
    const { phone_number } = req.body;
    if (!phone_number) {
        return res.status(200).json({
            code: '1002',
            message: 'Parameter is not enough',
            data: null,
        });
    }
    try {
        const user = await db_1.default.user.findUnique({
            where: { phone_number },
        });
        if (!user) {
            return res.status(200).json({
                code: '9995',
                message: 'User is not validated',
                data: null,
            });
        }
        // Sinh mã OTP 6 số
        const otp = Math.floor(100000 + Math.random() * 900000).toString();
        await db_1.default.user.update({
            where: { id: user.id },
            data: { reset_code: otp },
        });
        return res.status(200).json({
            code: '1000',
            message: 'OK',
            data: {
                reset_code: otp,
            },
        });
    }
    catch (error) {
        console.error('createCodeResetPassword error:', error);
        return res.status(200).json({
            code: '9999',
            message: 'Exception occurred',
            data: null,
        });
    }
};
exports.createCodeResetPassword = createCodeResetPassword;
const checkCodeResetPassword = async (req, res) => {
    const { phone_number, reset_code } = req.body;
    if (!phone_number || !reset_code) {
        return res.status(200).json({
            code: '1002',
            message: 'Parameter is not enough',
            data: null,
        });
    }
    try {
        const user = await db_1.default.user.findUnique({
            where: { phone_number },
        });
        if (!user || user.reset_code !== reset_code) {
            return res.status(200).json({
                code: '9993',
                message: 'Code verify is incorrect.',
                data: null,
            });
        }
        // Xóa reset_code sau khi xác thực thành công
        await db_1.default.user.update({
            where: { id: user.id },
            data: { reset_code: null },
        });
        return res.status(200).json({
            code: '1000',
            message: 'OK',
            data: 'Verify success',
        });
    }
    catch (error) {
        console.error('checkCodeResetPassword error:', error);
        return res.status(200).json({
            code: '9999',
            message: 'Exception occurred',
            data: null,
        });
    }
};
exports.checkCodeResetPassword = checkCodeResetPassword;
const setDevToken = async (req, res) => {
    const userId = req.user?.id;
    if (!userId) {
        return res.status(200).json({
            code: '9998',
            message: 'Token is invalid.',
            data: null,
        });
    }
    const { devtoken, devtype } = req.body;
    if (!devtoken || devtype === undefined) {
        return res.status(200).json({
            code: '1002',
            message: 'Parameter is not enough',
            data: null,
        });
    }
    try {
        await db_1.default.user.update({
            where: { id: userId },
            data: {
                dev_token: devtoken,
                dev_type: devtype.toString(),
            },
        });
        return res.status(200).json({
            code: '1000',
            message: 'OK',
            data: 'Device token set successfully',
        });
    }
    catch (error) {
        console.error('setDevToken error:', error);
        return res.status(200).json({
            code: '9999',
            message: 'Exception occurred',
            data: null,
        });
    }
};
exports.setDevToken = setDevToken;
const getPushSetting = async (req, res) => {
    const userId = req.user?.id;
    if (!userId) {
        return res.status(200).json({
            code: '9998',
            message: 'Token is invalid.',
            data: null,
        });
    }
    try {
        const user = await db_1.default.user.findUnique({
            where: { id: userId },
        });
        if (!user) {
            return res.status(200).json({
                code: '9995',
                message: 'User not found',
                data: null,
            });
        }
        return res.status(200).json({
            code: '1000',
            message: 'OK',
            data: {
                like: parseInt(user.push_like) || 0,
                comment: parseInt(user.push_comment) || 0,
                transaction: parseInt(user.push_transaction) || 0,
                announcement: parseInt(user.push_announcement) || 0,
                sound_on: parseInt(user.push_sound_on) || 0,
                sound_default: user.push_sound_default ? parseInt(user.push_sound_default) : 1,
            },
        });
    }
    catch (error) {
        console.error('getPushSetting error:', error);
        return res.status(200).json({
            code: '9999',
            message: 'Exception occurred',
            data: null,
        });
    }
};
exports.getPushSetting = getPushSetting;
const setPushSetting = async (req, res) => {
    const userId = req.user?.id;
    if (!userId) {
        return res.status(200).json({
            code: '9998',
            message: 'Token is invalid.',
            data: null,
        });
    }
    const { like, comment, transaction, announcement, sound_on, sound_default } = req.body;
    try {
        const dataToUpdate = {};
        if (like !== undefined)
            dataToUpdate.push_like = like.toString();
        if (comment !== undefined)
            dataToUpdate.push_comment = comment.toString();
        if (transaction !== undefined)
            dataToUpdate.push_transaction = transaction.toString();
        if (announcement !== undefined)
            dataToUpdate.push_announcement = announcement.toString();
        if (sound_on !== undefined)
            dataToUpdate.push_sound_on = sound_on.toString();
        if (sound_default !== undefined)
            dataToUpdate.push_sound_default = sound_default.toString();
        await db_1.default.user.update({
            where: { id: userId },
            data: dataToUpdate,
        });
        return res.status(200).json({
            code: '1000',
            message: 'OK',
            data: 'Settings updated successfully',
        });
    }
    catch (error) {
        console.error('setPushSetting error:', error);
        return res.status(200).json({
            code: '9999',
            message: 'Exception occurred',
            data: null,
        });
    }
};
exports.setPushSetting = setPushSetting;
const getMe = async (req, res) => {
    if (!req.user) {
        return res.status(200).json({
            code: '9998',
            message: 'Token is invalid.',
            data: null,
        });
    }
    try {
        const user = await db_1.default.user.findUnique({
            where: { id: req.user.id },
        });
        if (!user) {
            return res.status(200).json({
                code: '9995',
                message: 'User not found',
                data: null,
            });
        }
        return res.status(200).json({
            code: '1000',
            message: 'OK',
            data: {
                id: user.id,
                phonenumber: user.phone_number,
                username: user.username,
                email: user.email,
                firstname: user.firstname,
                lastname: user.lastname,
                address: user.address,
                city: user.city,
                avatar: user.avatar,
                cover_image: user.cover_image,
                cover_image_web: user.cover_image_web,
                status: user.status,
                listing: user.listing,
                online: user.online,
            },
        });
    }
    catch (error) {
        return res.status(200).json({
            code: '9999',
            message: 'Exception occurred',
            data: null,
        });
    }
};
exports.getMe = getMe;
