import { IsIn, IsISO8601, IsOptional, IsString } from 'class-validator';

export class ConfirmJobListingDto {
  @IsIn(['INTERNSHIP', 'PLACEMENT', 'GOVT_JOB']) type: string;
  @IsString() title: string;
  @IsString() company: string;
  @IsOptional() @IsString() description?: string;
  @IsString() applyUrl: string;
  @IsOptional() @IsISO8601() deadline?: string;
  @IsOptional() @IsString() branch?: string;
  @IsOptional() @IsString() s3Key?: string;
  @IsOptional() @IsString() publicUrl?: string;
}
