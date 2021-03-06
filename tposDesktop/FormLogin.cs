﻿using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Windows.Forms;
using System.Security.Cryptography;
using Classes;
using Classes.DB;
using tposDesktop.DataSetTposTableAdapters;
using MySql.Data;
using MySql.Data.MySqlClient;

namespace tposDesktop
{
    public partial class FormLogin : Form
    {

        private bool _dragging = false;
        private Point _offset;
        private Point _start_point = new Point(0, 0);
        private String KeyNumber = "";

        DBclass dbclass;
        Language lang;
        public FormLogin()
        {
            InitializeComponent();
            lang = Program.Lang;
            int w = this.Size.Width;
            int h = this.Size.Height;
            this.Icon = tposDesktop.Properties.Resources.mainIcon;
            //tbxLogin.Location = new Point(w / 2-tbxLogin.Width/2, tbxLogin.Location.Y);
            //tbxPass.Location = new Point(w / 2 - tbxPass.Width / 2, tbxPass.Location.Y);
            //btnLogin.Location = new Point(w / 2 - btnLogin.Width / 2, btnLogin.Location.Y);
            try
            {
                dbclass = new DBclass();
                userTableAdapter uTba = new userTableAdapter();
                uTba.Fill(DBclass.DS.user);
            }
            catch (Exception ex)
            {
                isMessage = true;
                MessageBox.Show("Нет подключения к Базе данных, "+ex.Message);
            }
            tbxLogin.Text = lang.Value("Login");
            tbxPass.Text = lang.Value("Pass");
            lblErr.Text = lang.Value("Err_Login");
            lblErr.BackColor = Color.FromArgb(144, 127, 255);

        }

        private void btnKeypress_Click(object sender, EventArgs e)
        {
            Button numBtn = sender as Button;
            
                tbxPassword.Text += numBtn.Text;
            
        }
        bool isMessage = false;
        public void LoadForm(object sender, EventArgs e)
        {
            if (Properties.Settings.Default.isAdmin)
            {
            }
            else
            {
                this.BackgroundImage = null;
                //this.TransparencyKey = Color.Transparent;
                btnPanel.Visible = true;
                btnExit.Visible= false;
                btnkassaexit.Visible = true;
                
            }
            if (isMessage)
            {
                this.Close();
 
            }
 
        }
        public string CalculateMD5Hash(string input)
        {

            // step 1, calculate MD5 hash from input

            MD5 md5 = System.Security.Cryptography.MD5.Create();
            byte[] inputBytes = System.Text.Encoding.UTF8.GetBytes(input);
            byte[] hash = md5.ComputeHash(inputBytes);

            // step 2, convert byte array to hex string
            StringBuilder sb = new StringBuilder();
            for (int i = 0; i < hash.Length; i++)
            {
                sb.Append(hash[i].ToString("x2"));
            }
            return sb.ToString();
        }

        private void buttonLogin_Click(object sender, EventArgs e)
        {
            //lblPassError.Visible = false;
            DataTable table = DBclass.DS.user;
            if (Properties.Settings.Default.isAdmin)
            {
                string hash = CalculateMD5Hash(CalculateMD5Hash(tbxPass.Text));
                DataRow[] rows = table.Select("username='" + tbxLogin.Text + "' and password='" + hash + "'");
                if (rows.Length != 0)
                {
                    foreach (DataRow dr in rows)
                    {
                        string role = dr["role"].ToString();
                        if (role == "admin")
                        {
                            Program.window_type = 3;
                        }
                        else if(role == "manager")
                        {
                            Program.window_type = 3;
                        }
                        else 
                        {
                            Program.window_type = 2;
                        }
                        UserValues.CurrentUserID = Convert.ToInt32(dr["IDUser"]);
                        UserValues.CurrentUser = dr["username"].ToString();
                        UserValues.role = role;
                        //MessageBox.Show(UserValues.CurrentUser+":"+role);

                        //Program.oldWindow_type = 3;
                        //Program.onClose = true;
                        this.Close();
                        return;

                    }


                }
                else
                {
                    lblErr.Visible = true;
                    lblErr.Text = lang.Value("Err_Login");

                }
            }
            else {

                string hash = CalculateMD5Hash(CalculateMD5Hash(tbxPassword.Text));
                DataRow[] rows = table.Select("role='user' and password='" + hash + "'");
                if (rows.Length != 0)
                {
                    foreach (DataRow dr in rows)
                    {
                        string role = dr["role"].ToString();
                        
                            Program.window_type = 2;
                        
                        UserValues.CurrentUserID = Convert.ToInt32(dr["IDUser"]);
                        UserValues.CurrentUser = dr["username"].ToString();
                        UserValues.role = role;
                        //MessageBox.Show(UserValues.CurrentUser+":"+role);

                        //Program.oldWindow_type = 3;
                        //Program.onClose = true;
                        this.Close();
                        return;

                    }


                }
                else
                {
                    lblErr.Visible = true;
                    lblErr.Text = lang.Value("Err_Login");

                }
            }


        }

        private void tbxEnter(object sender, EventArgs e)
        {
            lblErr.Visible = false;
            TextBox tbx = sender as TextBox;
            if (lang.Value("Login") == tbx.Text || lang.Value("Pass") == tbx.Text)
            {
                tbx.Text = "";
                tbx.ForeColor = Color.Black;
                if (lang.Value("Pass") == tbx.Text)
                {
                    tbx.PasswordChar = '0';
                }
            }
        }

        private void tbxLeave(object sender, EventArgs e)
        {
            
            TextBox tbx = sender as TextBox;
            if (tbx.Text == "")
            {
                if (tbx.Name == "tbxLogin")
                {
                    tbx.Text = lang.Value("Login");
                    
                }
                else if (tbx.Name == "tbxPass")
                {
                    tbx.Text = lang.Value("Pass");
                    
                }
                tbx.ForeColor = Color.Silver;
            }
        }

        private void tbxPass_KeyPress(object sender, KeyPressEventArgs e)
        {
            if (e.KeyChar == 13)
            {
                buttonLogin_Click(null, null);
            }
        }

        private void btnExit_Click(object sender, EventArgs e)
        {
            this.Close();
            Program.window_type = 0;
        }

        private void FormLogin_MouseDown(object sender, MouseEventArgs e)
        {
            _dragging = true;
            _start_point = new Point(e.X, e.Y);
        }

        private void FormLogin_MouseMove(object sender, MouseEventArgs e)
        {
            if (_dragging)
            {
                Point p = PointToScreen(e.Location);
                Location = new Point(p.X - this._start_point.X, p.Y - this._start_point.Y);

            }
        }

        private void FormLogin_MouseUp(object sender, MouseEventArgs e)
        {
            _dragging = false;
        }

        private void flowLayoutPanel2_Paint(object sender, PaintEventArgs e)
        {

        }

        private void key_dot_Click(object sender, EventArgs e)
        {
            if (tbxPassword.Text.Length > 0)
            {
                tbxPassword.Text = tbxPassword.Text.Remove(tbxPassword.Text.Length - 1);
            }
            
        }

        private void key_plus_Click(object sender, EventArgs e)
        {
            if (tbxPassword.Text.Length > 0)
            {
                tbxPassword.Text = "";
            }
            
        }

        private void btnkassaexit_Click(object sender, EventArgs e)
        {
            this.Close();
            Program.window_type = 0;
        }
    }
}
